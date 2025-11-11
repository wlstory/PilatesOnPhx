# Requirements Extraction Execution Guide

## Overview

This guide provides the practical steps to extract ALL requirements from the Wlstory (NextJS) and AltBuild-Rails teams and create comprehensive Phoenix/Elixir/Ash requirements for the AltBuild-PHX team.

## Prerequisites

- Linear API access configured
- Access to Wlstory team workspace
- Access to AltBuild-Rails team workspace
- Access to AltBuild-PHX team workspace
- Reference: PHOENIX_REQUIREMENTS_FRAMEWORK.md in this directory

## Recommended Approach: HYBRID STRATEGY

Given the scope (100+ issues), we recommend incremental execution:

### Phase 1: Data Extraction (Automated)
Use Linear API or CLI to fetch all issues and export to structured format

### Phase 2: Analysis & Prioritization (Manual Review)
Review, categorize by 13 domains, and prioritize

### Phase 3: Issue Creation (Incremental Batches)
Start with Sprint 2 critical features, get feedback, iterate

---

## Execution Steps

### STEP 1: Extract Requirements Using Linear Tools

You have two options for extraction:

#### Option A: Use Linear MCP Server (Recommended if configured)

The Linear MCP server should already be configured in your Claude environment. You can use these tools:
- `mcp__linear-server__list_teams` - Get team IDs
- `mcp__linear-server__list_issues` - Fetch issues with pagination
- `mcp__linear-server__get_issue` - Get full issue details

#### Option B: Use Linear CLI

```bash
# Install Linear CLI
npm install -g @linear/cli

# Authenticate
linear auth

# List teams to get IDs
linear team list

# Fetch issues from Wlstory team (replace TEAM_ID)
linear issue list --team TEAM_ID --limit 50 > wlstory_issues.txt

# For pagination, use --after flag
linear issue list --team TEAM_ID --limit 50 --after ISSUE_ID >> wlstory_issues.txt
```

### STEP 2: Categorize by Domain

Use the 13 domain categories from PHOENIX_REQUIREMENTS_FRAMEWORK.md:
1. Authentication & Multi-Tenant
2. Studio Management
3. Class Management
4. Client Management
5. Package System
6. Booking System
7. Attendance & Check-In
8. Payments & Billing
9. Communications
10. Reporting & Analytics
11. Automation & Background Jobs
12. Mobile/PWA Features
13. Admin Tools & Data Management

### STEP 3: Map to Phoenix/Elixir/Ash Patterns

For each requirement, determine:
- **LiveView component pattern** (multi-step form, modal, stream, etc.)
- **Ash resource and actions** needed
- **Oban workers** for background jobs
- **PubSub events** for real-time features
- **Ash policies** for authorization

### STEP 4: Create Phoenix Issues in Batches

#### Batch 1: Sprint 2 Core Workflows (15 issues - START HERE)

**Priority Features:**
1. Studio Onboarding Wizard (PHX-25)
2. Single Class Scheduling (PHX-32)
3. Recurring Class Series Creation (PHX-33)
4. Client Booking Workflow (PHX-51, PHX-52)
5. Class Type Management (PHX-31)
6. Studio Settings (PHX-27, PHX-28)
7. Client Profile Management (PHX-38, PHX-39)
8. Booking Cancellation (PHX-54)
9. Waitlist Management (PHX-55)

**For each issue, use the template from PHOENIX_REQUIREMENTS_FRAMEWORK.md Part 3:**

```markdown
# PHX-XXX: [Feature Title]

## Original Requirement
**Reference:** WLS-XXX or RAILS-XXX
**Original Team:** Wlstory (NextJS) / AltBuild-Rails

## User Story
As a [persona from Catalio.Documentation.Persona],
I can [activity],
so that [business benefit].

## Use Cases
[Gherkin scenarios: Happy Path, Edge Cases, Error Cases]

## Acceptance Criteria
[5-10 testable criteria]

## Technical Implementation Details
[Reusable modules, patterns, dependencies, security, performance, testing]

## Supporting Documentation
[Links to AGENTS.md and CLAUDE.md with line numbers]

## References
[Original issue URL, related PHX issues]

## Labels, Priority, Project, Milestone, Dependencies
[Set appropriately for Linear]
```

### STEP 5: Quality Checklist

Before creating each issue:
- [ ] Referenced original WLS/RAILS issue
- [ ] Used proper user story format with persona
- [ ] Included Happy Path, Edge Cases, Error Cases
- [ ] Listed 5-10 testable acceptance criteria
- [ ] Specified Ash resources, actions, and patterns
- [ ] Identified dependencies on Sprint 1 (PHX-1 through PHX-8)
- [ ] Defined testing strategy (85%+ coverage, business logic focus)
- [ ] Referenced AGENTS.md and CLAUDE.md with line numbers
- [ ] Set labels: feature, sprint-X, domain:X, priority:X
- [ ] Assigned to project and milestone
- [ ] Listed blocked-by and blocks relationships

---

## Recommended Batch Order

### Batch 1: Sprint 2 Core (15 issues) - CREATE FIRST
Focus on essential daily operations:
- Studio onboarding
- Class scheduling (single + recurring)
- Client booking
- Basic studio settings

### Batch 2: Sprint 2 Extended (10 issues)
- Package workflows
- Waitlist management
- Client profiles
- Advanced booking features

### Batch 3: Sprint 3 Automation (15 issues)
- Oban workers for reminders
- Email notifications
- Background jobs
- Basic reporting

### Batch 4: Sprint 4 Integrations (15 issues)
- Stripe payments
- Advanced reporting
- Admin tools
- Data management

### Batch 5: Sprint 5 Polish (10 issues)
- Mobile/PWA features
- Advanced UI/UX
- Performance optimizations

---

## Expected Deliverables

After completing all batches:
- **75+ Phoenix issues created** covering all NextJS/Rails features
- **Sprint roadmap** with clear dependencies
- **Coverage report** showing % of original requirements covered
- **Gap analysis** identifying features to skip or defer
- **Pattern documentation** for common Phoenix/Ash implementations

---

## Next Actions

1. **Start with Batch 1** - Focus on 15 Sprint 2 critical issues
2. **Use the PHX-25 example** from PHOENIX_REQUIREMENTS_FRAMEWORK.md as your model
3. **Get feedback early** after creating first 5 issues
4. **Iterate and improve** based on feedback
5. **Continue with remaining batches** once approach is validated

Good luck!
