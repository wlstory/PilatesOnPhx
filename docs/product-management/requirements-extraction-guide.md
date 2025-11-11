# Requirements Extraction Guide

## Overview

This guide provides step-by-step instructions for extracting requirements from the NextJS (Wlstory) and Rails (AltBuild-Rails) teams and translating them into Phoenix/Elixir/Ash user stories for the AltBuild-PHX team.

---

## Prerequisites

Before starting, ensure you have:

1. **Linear MCP Access**: Ability to query Linear issues via MCP tools
2. **Team Context**: Understanding of:
   - **Wlstory**: NextJS/React/Supabase implementation
   - **AltBuild-Rails**: Ruby on Rails implementation
   - **AltBuild-PHX**: Phoenix/Elixir/Ash target implementation
3. **Domain Knowledge**: Familiarity with 4-domain architecture (see `domain-architecture-4domains.md`)

---

## Phase 1: Extract Requirements from Wlstory Team (NextJS)

### Step 1.1: Query High-Priority Issues

Use Linear MCP to fetch issues in batches of 20:

```bash
# Batch 1: Studio onboarding and setup
mcp__linear__list_issues(
  team="Wlstory",
  limit=20,
  query="studio onboarding class setup configuration"
)

# Batch 2: Booking and package features
mcp__linear__list_issues(
  team="Wlstory", 
  limit=20,
  query="booking package waitlist purchase"
)

# Batch 3: Recurring and automation
mcp__linear__list_issues(
  team="Wlstory",
  limit=20,
  query="recurring scheduled automation background"
)

# Batch 4: Reports and analytics
mcp__linear__list_issues(
  team="Wlstory",
  limit=20,
  query="report analytics dashboard metrics"
)

# Batch 5: Notifications and communications
mcp__linear__list_issues(
  team="Wlstory",
  limit=20,
  query="notification email sms reminder"
)
```

### Step 1.2: Key Issues Already Identified

Based on project context, prioritize these issues:

- **WLS-101**: Studio Onboarding Wizard (6-step wizard)
- **WLS-97**: Recurring Class Series
- **WLS-98**: Package Conversion Workflow
- **WLS-99**: Scheduled Reports
- **WLS-100**: Studio Configuration Settings
- **WLS-108**: Owner Account Setup
- **WLS-116**: Gap Analysis
- **WLS-126**: Legacy App Feature Parity

### Step 1.3: Categorize by Domain

For each extracted issue, assign to domain:

| Domain | Issues |
|--------|--------|
| **Accounts** | User authentication, role management, organization setup |
| **Studios** | Studio profile, staff management, room/equipment setup, configuration |
| **Classes** | Class types, schedules, recurring templates, attendance |
| **Bookings** | Client profiles, package purchase, booking workflow, waitlist |

### Step 1.4: Categorize by Sprint

| Sprint | Focus | Issues |
|--------|-------|--------|
| **Sprint 1** | Foundation | Domain setup, core resources, policies |
| **Sprint 2** | Core Workflows | Onboarding, scheduling, booking |
| **Sprint 3** | Automation | Oban jobs, reminders, attendance |
| **Sprint 4** | Integrations | Payments, reporting, mobile |

---

## Phase 2: Extract Requirements from AltBuild-Rails Team

### Step 2.1: Query Rails Issues

Use same pagination strategy:

```bash
# Batch 1: Core models and workflows
mcp__linear__list_issues(
  team="AltBuild-Rails",
  limit=20,
  query="model controller workflow"
)

# Batch 2: ActiveJob and background processing
mcp__linear__list_issues(
  team="AltBuild-Rails",
  limit=20,
  query="job worker background sidekiq"
)

# Batch 3: Views and user interface
mcp__linear__list_issues(
  team="AltBuild-Rails",
  limit=20,
  query="view template form component"
)
```

### Step 2.2: Identify Rails-Specific Patterns

Document patterns unique to Rails implementation:

- **ActiveRecord patterns**: Translate to Ash resources
- **ActiveJob workers**: Translate to Oban workers
- **Rails controllers**: Translate to LiveView components
- **Rails validations**: Translate to Ash validations

### Step 2.3: Map Rails to Phoenix Equivalents

| Rails Pattern | Phoenix/Ash Equivalent |
|---------------|------------------------|
| `ActiveRecord::Base` | Ash.Resource |
| `belongs_to :studio` | `belongs_to :studio, Studios.Studio` |
| `validates :name, presence: true` | `validate present([:name])` |
| `after_create :send_email` | `change after_action(&send_email/2)` |
| `ActiveJob` | Oban.Worker |
| Controller action | LiveView event handler |
| View template | HEEx template |

---

## Phase 3: Create Linear Epics for AltBuild-PHX

### Step 3.1: Epic Structure

Each epic should have:

- **Title**: `[Epic Name] - [Brief Description]`
- **Priority**: Critical/High/Medium/Low
- **Estimated Stories**: Number of user stories
- **Business Value**: Why this epic matters
- **Project**: Assigned to appropriate sprint project
- **Milestone**: Sprint 2/3/4 milestone
- **Labels**: `epic`, `feature`

### Step 3.2: Epic Template

```markdown
### Epic PHX-X: [Epic Name]

**Parent**: None (or parent epic ID)
**Priority**: [Critical/High/Medium/Low]
**Estimated Stories**: [Number]
**Business Value**: [Business justification]
**Project**: [Sprint X project]
**Milestone**: Sprint X
**Labels**: epic, feature, [domain]

**Description**: 
[1-2 paragraph description of the epic's scope and goals]

**Acceptance Criteria**:
- [High-level criterion 1]
- [High-level criterion 2]
- [High-level criterion 3]

**User Stories**:
- PHX-X1: [Story 1 title]
- PHX-X2: [Story 2 title]
- PHX-X3: [Story 3 title]
...

**Dependencies**:
- Depends on: [Other epic or foundation work]

**Success Metrics**:
- [Metric 1: e.g., "50% of studios complete onboarding"]
- [Metric 2: e.g., "Average time to book class < 30 seconds"]
```

### Step 3.3: Recommended Epics

Based on requirements analysis, create these epics:

**Sprint 2 Epics**:
1. **PHX-9**: Studio Onboarding & Setup (6 stories)
2. **PHX-16**: Class Scheduling & Recurring Classes (5 stories)
3. **PHX-22**: Booking Workflow & Package Management (8 stories)

**Sprint 3 Epics**:
4. **PHX-31**: Attendance & Check-In System (4 stories)
5. **PHX-36**: Automation & Background Jobs (5 stories)
6. **PHX-42**: Client & Instructor Dashboards (4 stories)

**Sprint 4 Epics**:
7. **PHX-47**: Payments & Stripe Integration (6 stories)
8. **PHX-54**: Reporting & Analytics (5 stories)
9. **PHX-60**: Mobile PWA & Advanced UX (4 stories)

---

## Phase 4: Create User Stories Under Epics

### Step 4.1: User Story Structure

Each user story must include:

1. **Metadata Fields** (REQUIRED):
   - Title
   - Priority (REQUIRED)
   - Labels (REQUIRED - at least one)
   - Project (REQUIRED)
   - Milestone (RECOMMENDED)
   - Parent (Epic ID)

2. **Description** (following template):
   - Original Requirement (source issue)
   - User Story statement
   - Use Cases (Gherkin: Happy/Edge/Error)
   - Acceptance Criteria
   - Phoenix/Ash Implementation
   - Testing Strategy
   - Dependencies
   - References

### Step 4.2: Use Story Template

See `linear-issue-template.md` for complete template.

### Step 4.3: Story Creation Workflow

For EACH extracted requirement:

1. **Analyze Original**:
   - Read Wlstory/Rails issue
   - Identify core functionality
   - Note technical approach

2. **Map to Domain**:
   - Assign to primary domain (Accounts/Studios/Classes/Bookings)
   - Identify cross-domain dependencies

3. **Write User Story**:
   - Define actor (role/persona)
   - Define action (what they do)
   - Define benefit (why they do it)

4. **Define Use Cases**:
   - Happy Path (at least 1)
   - Edge Cases (at least 1-2)
   - Error Cases (at least 1)

5. **Specify Implementation**:
   - Ash resources and actions
   - LiveView components
   - Oban jobs (if background work)
   - PubSub events (if real-time)
   - Database migrations

6. **Define Testing**:
   - Resource action tests
   - LiveView tests
   - Oban job tests (if applicable)
   - Integration tests

7. **Set Metadata**:
   - Priority based on business value
   - Labels (feature, domain tag)
   - Project (sprint assignment)
   - Parent (epic)

---

## Phase 5: Prioritization and Sprint Assignment

### Step 5.1: Priority Levels

| Priority | When to Use |
|----------|-------------|
| **Critical** | MVP blocker, must be done for launch |
| **High** | Important for UX, early adopter value |
| **Medium** | Nice to have, enhances experience |
| **Low** | Future enhancement, not urgent |
| **Todo** | Not yet prioritized, needs refinement |

### Step 5.2: Sprint Assignment Guidelines

**Sprint 1 (Foundation)**:
- All domain architecture work
- Core resource definitions
- Multi-tenant policies
- Testing framework

**Sprint 2 (Core Workflows)**:
- Studio onboarding wizard
- Class scheduling basics
- Booking workflow MVP
- Package purchase

**Sprint 3 (Automation)**:
- Recurring class generation
- Email/SMS reminders
- Attendance tracking
- Waitlist automation

**Sprint 4 (Integrations)**:
- Stripe payment processing
- Financial reporting
- Mobile PWA features
- Analytics dashboards

### Step 5.3: Dependency Mapping

Create dependency graph:

```
PHX-1 (Domain Architecture)
  ├─> PHX-2 (Accounts Domain)
  ├─> PHX-3 (Studios Domain)
  ├─> PHX-4 (Classes Domain)
  └─> PHX-5+6 (Bookings Domain)

PHX-2 (Accounts)
  └─> PHX-10 (Studio Info) - needs User actor

PHX-3 (Studios)
  └─> PHX-10 (Studio Info)
      └─> PHX-11 (Business Model)
          └─> PHX-12 (Staff Setup)
              └─> PHX-13 (Class Types)
                  └─> PHX-14 (Initial Schedule)
                      └─> PHX-15 (Launch)
```

---

## Phase 6: Create Projects and Milestones

### Step 6.1: Project Structure

Create Linear projects for each sprint:

**Project 1: Foundational Setup**
- Issues: PHX-1 through PHX-8
- Duration: 2 weeks
- Focus: Domain architecture

**Project 2: Sprint 2 - Core Workflows**
- Issues: PHX-9 through PHX-30
- Duration: 3 weeks
- Focus: Onboarding, scheduling, booking

**Project 3: Sprint 3 - Automation**
- Issues: PHX-31 through PHX-46
- Duration: 3 weeks
- Focus: Background jobs, attendance

**Project 4: Sprint 4 - Integrations**
- Issues: PHX-47 through PHX-64
- Duration: 3 weeks
- Focus: Payments, reporting, mobile

### Step 6.2: Milestone Structure

Create milestones for grouping related work:

- **Sprint 1 - Foundation**: All domain setup work
- **Sprint 2 - MVP Features**: First deployable version
- **Sprint 3 - Automation**: Background automation
- **Sprint 4 - Polish**: Production-ready quality

---

## Phase 7: Quality Assurance

### Step 7.1: Issue Checklist

Before creating each Linear issue, verify:

- [ ] Title is clear and descriptive
- [ ] Priority is set (REQUIRED)
- [ ] At least one label is set (REQUIRED)
- [ ] Project is assigned (REQUIRED)
- [ ] Milestone is set (RECOMMENDED)
- [ ] Parent epic linked (if applicable)
- [ ] User story follows format "As a [role], I want [action], so that [benefit]"
- [ ] At least 1 happy path use case
- [ ] At least 1 error case use case
- [ ] Acceptance criteria are testable
- [ ] Phoenix/Ash implementation specified
- [ ] Testing strategy defined
- [ ] Dependencies listed
- [ ] References included

### Step 7.2: Coverage Analysis

Track coverage of original requirements:

```
Total NextJS Requirements: [X]
Total Rails Requirements: [Y]
Total Phoenix Issues Created: [Z]

Coverage: Z / (X + Y) = [percentage]%

Goal: 100% coverage of critical requirements
```

### Step 7.3: Gap Analysis

Identify gaps:

- Features in Wlstory but not in Rails
- Features in Rails but not in Wlstory
- Features needed for Phoenix but not in either
- Technical requirements unique to Phoenix/Ash

---

## Phase 8: Final Report

### Step 8.1: Summary Report Template

```markdown
# Requirements Extraction Summary

## Overview

**Date**: [Date]
**Extracted By**: [Name]
**Teams Analyzed**: Wlstory (NextJS), AltBuild-Rails

---

## Sprint 1 Updates

### Issues Updated
- PHX-1: Updated to reflect 4-domain architecture
- PHX-5+6: Merged into single Bookings domain issue

---

## Epics Created

### Sprint 2 Epics
- PHX-9: Studio Onboarding & Setup (6 stories)
- PHX-16: Class Scheduling & Recurring Classes (5 stories)
- PHX-22: Booking Workflow & Package Management (8 stories)

### Sprint 3 Epics
- PHX-31: Attendance & Check-In System (4 stories)
- PHX-36: Automation & Background Jobs (5 stories)
- PHX-42: Client & Instructor Dashboards (4 stories)

### Sprint 4 Epics
- PHX-47: Payments & Stripe Integration (6 stories)
- PHX-54: Reporting & Analytics (5 stories)
- PHX-60: Mobile PWA & Advanced UX (4 stories)

**Total Epics**: 9

---

## User Stories Created

### By Epic

#### Epic PHX-9: Studio Onboarding
- PHX-10: Studio Basic Information Capture
- PHX-11: Business Model Selection
- PHX-12: Staff and Instructor Setup
- PHX-13: Class Type Definition
- PHX-14: Initial Schedule Creation
- PHX-15: Onboarding Completion and Launch

#### Epic PHX-16: Class Scheduling
- PHX-17: Create Single Class Session
- PHX-18: Create Recurring Class Schedule
- PHX-19: Generate Sessions (Oban)
- PHX-20: Edit/Cancel Sessions
- PHX-21: Instructor Substitution

#### Epic PHX-22: Booking Workflow
- PHX-23: Client Registration
- PHX-24: Browse Classes
- PHX-25: Purchase Package
- PHX-26: Book Class
- PHX-27: Waitlist Entry
- PHX-28: Cancel Booking
- PHX-29: Package Expiration
- PHX-30: Admin Dashboard

[Continue for all epics...]

**Total Stories**: 55+

---

## Requirements Coverage

### NextJS (Wlstory)
- Requirements Extracted: [X]
- Mapped to Phoenix Issues: [Y]
- Coverage: [Y/X]%

### Rails (AltBuild-Rails)
- Requirements Extracted: [A]
- Mapped to Phoenix Issues: [B]
- Coverage: [B/A]%

### Overall Coverage
- Total Requirements: [X + A]
- Total Phoenix Issues: [Z]
- Coverage: [percentage]%

---

## Domain Distribution

| Domain | Issues | Percentage |
|--------|--------|------------|
| Accounts | [X] | [%] |
| Studios | [Y] | [%] |
| Classes | [Z] | [%] |
| Bookings | [A] | [%] |

---

## Sprint Distribution

| Sprint | Epics | Stories | Duration |
|--------|-------|---------|----------|
| Sprint 1 | - | 8 | 2 weeks |
| Sprint 2 | 3 | 19+ | 3 weeks |
| Sprint 3 | 3 | 13+ | 3 weeks |
| Sprint 4 | 3 | 15+ | 3 weeks |

**Total**: 9 epics, 55+ stories, 11 weeks

---

## Gap Analysis

### Features Not in Original Requirements
1. [Feature 1]: [Why needed for Phoenix]
2. [Feature 2]: [Why needed for Phoenix]

### Features Deferred
1. [Feature 1]: [Reason for deferral]
2. [Feature 2]: [Reason for deferral]

---

## Recommendations

1. **Prioritization**: [Recommendation]
2. **Sequencing**: [Recommendation]
3. **Risk Mitigation**: [Recommendation]
4. **Resource Allocation**: [Recommendation]

---

## Next Steps

1. Review and approve epic structure
2. Refine user stories with stakeholders
3. Begin Sprint 1 foundation work
4. Set up Linear projects and milestones
5. Assign team members to initial issues

```

---

## Tools and Resources

### Linear MCP Tools

- `mcp__linear__list_issues()` - Query issues
- `mcp__linear__create_issue()` - Create new issue
- `mcp__linear__update_issue()` - Update existing issue
- `mcp__linear__list_projects()` - List available projects
- `mcp__linear__list_issue_labels()` - List available labels
- `mcp__linear__list_milestones()` - List available milestones

### Documentation References

- `domain-architecture-4domains.md` - Domain structure
- `sprint-planning-epics.md` - Epic and story breakdown
- `linear-issue-template.md` - Issue creation template
- `CLAUDE.md` - Project conventions
- `AGENTS.md` - Phoenix/Ash patterns

---

## Quality Standards

### Every Issue Must Have

1. **Clear Business Value**: Why does this matter?
2. **Testable Acceptance Criteria**: How do we know it's done?
3. **Implementation Details**: How will we build it?
4. **Testing Strategy**: How will we verify it works?
5. **Dependencies**: What must be done first?

### Red Flags to Avoid

- Vague user stories without clear actors or benefits
- Missing use cases (especially error cases)
- No implementation details
- Untestable acceptance criteria
- Missing dependencies
- No priority set
- No project assignment

---

## Success Criteria

### Requirements Extraction Success

- [ ] 100% of critical NextJS requirements extracted
- [ ] 100% of critical Rails requirements extracted
- [ ] All requirements mapped to Phoenix issues
- [ ] All epics created with clear business value
- [ ] All user stories follow template
- [ ] All issues have required metadata
- [ ] Dependency graph created
- [ ] Sprint assignments made
- [ ] Projects and milestones created
- [ ] Final summary report generated

### Quality Metrics

- Test coverage target: 85%+
- Issue completion rate: 90%+
- Business value delivered: 100% of MVP features
- Technical debt: < 10% of total work

