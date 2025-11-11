# Requirements Extraction Plan - NextJS & Rails Teams

## Overview

This document outlines the process for extracting requirements from the Wlstory (NextJS) and AltBuild-Rails teams to identify additional features and patterns not yet covered in the Phoenix/Elixir/Ash rewrite roadmap.

## Extraction Strategy

### 1. Linear API Queries

Use Linear's API or MCP Linear server to fetch issues from:
- **Wlstory Team**: NextJS/React implementation issues
- **AltBuild-Rails Team**: Rails implementation issues

### 2. Query Parameters

For each team, fetch issues with pagination:
- **Limit**: 50 issues per request
- **Filters**: 
  - Status: All (including completed, to understand full scope)
  - Labels: Feature, enhancement, bug fix (patterns)
- **Include**: Description, acceptance criteria, comments, linked issues

### 3. Analysis Focus

#### From NextJS Team (Wlstory)
Identify patterns to adapt from React to Phoenix LiveView:

| NextJS/React Pattern | Phoenix/LiveView Adaptation |
|---------------------|----------------------------|
| React components | LiveView components with HEEx |
| useState/useEffect | LiveView assigns and lifecycle |
| React Context | LiveView assigns or process state |
| REST API calls | Ash actions + LiveView events |
| Client-side routing | LiveView navigation (navigate/patch) |
| Form libraries (React Hook Form) | Phoenix.Component.form + to_form/2 |
| Real-time subscriptions | Phoenix Channels or PubSub |
| API client (Axios/Fetch) | Ash queries in LiveView |
| CSS-in-JS | Tailwind CSS classes |
| Component libraries (Radix UI) | Phoenix CoreComponents |

#### From Rails Team (AltBuild-Rails)
Identify patterns to adapt from Rails to Phoenix/Ash:

| Rails Pattern | Phoenix/Ash Adaptation |
|--------------|------------------------|
| ActiveRecord models | Ash resources |
| Controllers/Actions | Ash actions + LiveView or Phoenix controllers |
| ActiveRecord validations | Ash validations and changes |
| Callbacks (before_save, etc.) | Ash changes and preparations |
| Background jobs (Sidekiq) | Oban workers |
| Mailers | Phoenix.Swoosh + Oban |
| Service objects | Ash actions or standalone modules |
| Pundit/CanCanCan authorization | Ash policies |
| Scopes | Ash filters and calculations |
| Migrations | Ecto migrations (via Ash Postgres) |

## Extraction Checklist

### Phase 1: Initial Fetch (30 minutes)

- [ ] Fetch first 50 issues from Wlstory team
- [ ] Fetch first 50 issues from AltBuild-Rails team
- [ ] Categorize by feature area (booking, payments, notifications, etc.)
- [ ] Identify issues already covered in PHX-9 through PHX-26

### Phase 2: Gap Analysis (1 hour)

For each issue from external teams, determine:

1. **Already Covered**: Is this feature already in PHX-9 through PHX-26?
   - If yes: Add any missing details to existing issue
   
2. **New Feature**: Is this a new feature not yet planned?
   - If yes: Create new issue draft with adaptation notes
   
3. **Enhancement**: Does this enhance an existing planned feature?
   - If yes: Add acceptance criteria to existing issue

4. **Out of Scope**: Is this specific to NextJS/Rails and not applicable?
   - If yes: Document why it's not applicable

### Phase 3: Adaptation Mapping (1-2 hours)

For each new or enhanced feature, document:

- **Original Tech Stack**: React/Rails implementation details
- **Phoenix/Ash Equivalent**: How it maps to Phoenix/Elixir/Ash patterns
- **Business Logic**: Core requirements independent of technology
- **UI/UX Patterns**: User experience requirements
- **Integration Points**: External services, APIs, webhooks

### Phase 4: New Issue Creation (1-2 hours)

For features not covered in PHX-9 through PHX-26:

- Create issue following same format as roadmap
- Include user story, use cases, acceptance criteria
- Document Phoenix/Elixir/Ash implementation patterns
- Assign priority and estimate
- Link dependencies
- Add to appropriate sprint or backlog

## Common Feature Areas to Investigate

### Booking & Scheduling
- Class series (multi-class bookings)
- Private sessions (1-on-1 with instructor)
- Equipment reservation
- Room/studio allocation
- Substitute instructor assignment

### Client Management
- Client notes (instructor observations)
- Health/injury tracking
- Goal setting and progress tracking
- Client tags/segmentation
- Family/group accounts

### Financial Management
- Refund processing
- Partial refunds
- Package transfers
- Gift certificates
- Discount codes/promotions
- Tax reporting

### Staff Management
- Payroll integration
- Commission tracking
- Instructor certification tracking
- Availability management
- Shift scheduling

### Studio Operations
- Facility maintenance tracking
- Equipment inventory
- Cleaning schedules
- Supply ordering
- Multi-location management

### Marketing & Communications
- Email campaigns
- Client segmentation for marketing
- Referral program
- Review/testimonial collection
- Social media integration

### Advanced Features
- Video streaming integration
- Virtual classes
- On-demand content
- Community features (forums, social)
- Loyalty programs

## Issue Template for Extracted Requirements

```markdown
# [Feature Name]

**Source**: Extracted from [Team Name] issue [Issue ID]

## Original Implementation
- **Team**: Wlstory / AltBuild-Rails
- **Tech Stack**: React/NextJS OR Ruby on Rails
- **Original Issue**: [Link to Linear issue]

## Adaptation Notes
[How this maps from React/Rails to Phoenix/Elixir/Ash]

## User Story
As a [role], I can [activity], so that [benefit]

## Use Cases
[Gherkin scenarios: Happy path, edge cases, error cases]

## Acceptance Criteria
1. [Criteria 1]
2. [Criteria 2]
...

## Technical Implementation Details
[Phoenix/Elixir/Ash specific patterns]

## Dependencies
- PHX-X: [Dependency description]
- External: [If any]

## Priority
[Urgent/High/Medium/Low based on business value]

## Estimate
[Story points]
```

## Automation Scripts

### Linear API Query Example (using curl)

```bash
# Fetch issues from Wlstory team
curl -X POST https://api.linear.app/graphql \
  -H "Authorization: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "query { issues(filter: { team: { name: { eq: \"Wlstory\" } } }, first: 50) { nodes { id title description state { name } labels { nodes { name } } } pageInfo { hasNextPage endCursor } } }"
  }'

# Fetch issues from AltBuild-Rails team
curl -X POST https://api.linear.app/graphql \
  -H "Authorization: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "query { issues(filter: { team: { name: { eq: \"AltBuild-Rails\" } } }, first: 50) { nodes { id title description state { name } labels { nodes { name } } } pageInfo { hasNextPage endCursor } } }"
  }'
```

### MCP Linear Server Example

If MCP Linear server is available:

```
# List Wlstory team issues
mcp__linear-server__list_issues --team_id="WLSTORY_TEAM_ID" --limit=50

# List AltBuild-Rails team issues
mcp__linear-server__list_issues --team_id="RAILS_TEAM_ID" --limit=50
```

## Expected Outcomes

After completing this extraction process:

1. **New Issues Identified**: 5-15 additional feature issues
2. **Enhanced Issues**: 3-8 existing issues with additional acceptance criteria
3. **Pattern Library**: Documented mapping of React/Rails → Phoenix/Ash patterns
4. **Updated Roadmap**: Comprehensive backlog of all PilatesOnPhx features
5. **Priority Refinement**: Adjusted priorities based on cross-team patterns

## Timeline

- **Phase 1**: 30 minutes (Initial fetch)
- **Phase 2**: 1 hour (Gap analysis)
- **Phase 3**: 1-2 hours (Adaptation mapping)
- **Phase 4**: 1-2 hours (New issue creation)
- **Total**: 3.5-5.5 hours

## Deliverables

1. **Gap Analysis Report**: Document listing all extracted requirements
2. **New Linear Issues**: Created in Linear with full specifications
3. **Enhancement Updates**: Existing issues updated with new criteria
4. **Pattern Mapping Guide**: React/Rails → Phoenix/Ash conversion patterns

## Follow-up Actions

After extraction:

1. Review new issues with Product Owner
2. Prioritize backlog
3. Assign to future sprints (Sprint 5+)
4. Update project roadmap
5. Conduct team knowledge sharing session

---

**Status**: Ready to execute  
**Owner**: Product Manager / BSA  
**Last Updated**: 2025-11-10
