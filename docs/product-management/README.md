# Product Management Documentation

This directory contains comprehensive product management documentation for the PilatesOnPhx Phoenix/Elixir/Ash rewrite project.

---

## Quick Start

**Start here**: Read `EXECUTIVE-SUMMARY.md` for a complete overview.

**Next steps**:
1. Review `domain-architecture-4domains.md` to understand the 4-domain design
2. Study `sprint-planning-epics.md` for the full epic and story breakdown
3. Use `linear-issue-template.md` when creating Phoenix/Ash user stories
4. Follow `requirements-extraction-guide.md` for extracting requirements from source teams

---

## Document Index

### 1. EXECUTIVE-SUMMARY.md
**Purpose**: High-level overview of the entire product management effort

**Contents**:
- Mission statement
- 4-domain architecture decision and rationale
- Sprint planning overview (4 sprints, 11 weeks)
- 9 epics, 55+ user stories breakdown
- Requirements extraction strategy
- Quality standards and success criteria
- Risk mitigation and next steps

**Audience**: Stakeholders, product managers, development leads

**When to read**: First document to read for project context

---

### 2. domain-architecture-4domains.md
**Purpose**: Detailed technical specification of the 4-domain architecture

**Contents**:
- Domain-by-domain breakdown (Accounts, Studios, Classes, Bookings)
- Resource allocation per domain
- Cross-domain interactions and dependencies
- Migration from 5-domain to 4-domain rationale
- Impact on Sprint 1 issues (PHX-1 through PHX-8)
- Benefits: reduced complexity, improved cohesion, better performance
- Domain design principles (multi-tenant, actor-based, testability)

**Audience**: Architects, senior developers, product managers

**When to read**: Before designing any features or creating resources

---

### 3. sprint-planning-epics.md
**Purpose**: Complete sprint breakdown with epics and user stories

**Contents**:

**Sprint 1 (Foundation - 2 weeks)**:
- PHX-1 through PHX-8: Domain setup, resources, policies

**Sprint 2 (Core Workflows - 3 weeks)**:
- Epic PHX-9: Studio Onboarding (6 stories: PHX-10 through PHX-15)
- Epic PHX-16: Class Scheduling (5 stories: PHX-17 through PHX-21)
- Epic PHX-22: Booking Workflow (8 stories: PHX-23 through PHX-30)

**Sprint 3 (Automation - 3 weeks)**:
- Epic PHX-31: Attendance & Check-In (4 stories)
- Epic PHX-36: Automation & Background Jobs (5 stories)
- Epic PHX-42: Dashboards (4 stories)

**Sprint 4 (Integrations - 3 weeks)**:
- Epic PHX-47: Stripe Payments (6 stories)
- Epic PHX-54: Reporting & Analytics (5 stories)
- Epic PHX-60: Mobile PWA (4 stories)

**Audience**: Product managers, scrum masters, developers

**When to read**: For sprint planning and backlog grooming

---

### 4. linear-issue-template.md
**Purpose**: Comprehensive template for creating Phoenix/Ash user stories in Linear

**Contents**:
- Required metadata fields (Priority, Labels, Project, Milestone)
- User story format with persona references
- Use cases in Gherkin format (Happy/Edge/Error)
- Acceptance criteria guidelines
- Phoenix/Ash implementation details:
  - Domain assignment
  - Resource and action definitions
  - LiveView components
  - Oban background jobs
  - PubSub real-time events
  - Database migrations
- Testing strategy (85%+ coverage target)
- Reusable patterns and code references
- Dependencies and blocking issues
- Security and performance considerations
- Definition of Done checklist

**Audience**: Product managers, business analysts, developers creating Linear issues

**When to read**: Every time you create a new Linear issue for Phoenix/Ash team

---

### 5. requirements-extraction-guide.md
**Purpose**: Step-by-step methodology for extracting requirements from source teams

**Contents**:

**Phase 1**: Extract from NextJS (Wlstory)
- Paginated Linear queries (batches of 20)
- Key issues identified (WLS-101, WLS-97, WLS-98, etc.)
- Categorization by domain and sprint

**Phase 2**: Extract from Rails (AltBuild-Rails)
- Rails pattern identification
- Mapping Rails → Phoenix/Ash equivalents
- ActiveRecord → Ash Resources, ActiveJob → Oban

**Phase 3**: Create Linear epics
- Epic structure and template
- 9 recommended epics across 4 sprints

**Phase 4**: Create user stories
- Story creation workflow (7 steps)
- Use of linear-issue-template.md

**Phase 5**: Prioritization and sprint assignment
- Priority levels (Critical/High/Medium/Low)
- Sprint assignment guidelines
- Dependency mapping

**Phase 6**: Projects and milestones
- Linear project structure
- Milestone creation

**Phase 7**: Quality assurance
- Issue checklist
- Coverage analysis
- Gap analysis

**Phase 8**: Final report
- Summary report template
- Coverage metrics

**Audience**: Product managers, business analysts

**When to read**: Before extracting requirements from source teams

---

## Workflow Summary

### For Product Managers

1. **Planning Phase**:
   - Read `EXECUTIVE-SUMMARY.md` for context
   - Review `domain-architecture-4domains.md` for architecture
   - Study `sprint-planning-epics.md` for sprint structure

2. **Requirements Extraction**:
   - Follow `requirements-extraction-guide.md` step-by-step
   - Query Wlstory and AltBuild-Rails Linear issues
   - Categorize by domain and sprint

3. **Issue Creation**:
   - Use `linear-issue-template.md` for every issue
   - Ensure all required metadata set (Priority, Labels, Project)
   - Include complete implementation details
   - Define testing strategy

4. **Quality Assurance**:
   - Verify issue checklist before creating
   - Track coverage of source requirements
   - Identify and document gaps

5. **Reporting**:
   - Generate final coverage report
   - Document recommendations and next steps

### For Developers

1. **Onboarding**:
   - Read `EXECUTIVE-SUMMARY.md` for project overview
   - Study `domain-architecture-4domains.md` for architecture
   - Review `/Users/wlstory/src/PilatesOnPhx/CLAUDE.md` for project conventions
   - Review `/Users/wlstory/src/PilatesOnPhx/AGENTS.md` for Phoenix/Ash patterns

2. **Sprint Planning**:
   - Review `sprint-planning-epics.md` for sprint scope
   - Understand epic and story relationships
   - Identify dependencies

3. **Implementation**:
   - Reference Linear issues created from templates
   - Follow Phoenix/Ash implementation details
   - Maintain 85%+ test coverage
   - Use patterns from AGENTS.md

4. **Testing**:
   - Focus on business logic (not framework features)
   - Test custom validations, policies, actions
   - Test cross-domain workflows
   - Test edge cases and error handling

### For Stakeholders

1. **Strategic Review**:
   - Read `EXECUTIVE-SUMMARY.md` for complete overview
   - Review 4-domain architecture decision
   - Approve sprint plan (11 weeks, 4 sprints)

2. **Sprint Reviews**:
   - Reference `sprint-planning-epics.md` for sprint goals
   - Review success criteria per sprint
   - Track progress against 55+ user stories

3. **Risk Management**:
   - Review risk mitigation strategies in EXECUTIVE-SUMMARY
   - Monitor test coverage (target 85%+)
   - Track issue completion rate (target 90%+)

---

## Key Metrics

### Project Scope

- **Total Sprints**: 4 (11 weeks)
- **Total Epics**: 9+
- **Total User Stories**: 55+
- **Domains**: 4 (Accounts, Studios, Classes, Bookings)

### Quality Targets

- **Test Coverage**: 85%+ on business logic
- **Issue Completion**: 90%+ completion rate
- **Technical Debt**: < 10% of total work
- **Requirements Coverage**: 100% of critical features

### Sprint Breakdown

| Sprint | Duration | Focus | Stories |
|--------|----------|-------|---------|
| Sprint 1 | 2 weeks | Foundation | 8 |
| Sprint 2 | 3 weeks | Core Workflows | 19+ |
| Sprint 3 | 3 weeks | Automation | 13+ |
| Sprint 4 | 3 weeks | Integrations | 15+ |

---

## Phoenix/Elixir/Ash Advantages

### Why This Tech Stack?

1. **Declarative Resources**: Ash resources > ActiveRecord
2. **Built-in Multi-Tenant**: Actor-based authorization out of the box
3. **Real-Time by Default**: LiveView > React + WebSocket complexity
4. **Concurrent Jobs**: Oban + BEAM > Sidekiq + threads
5. **Type Safety**: Pattern matching + Dialyzer > Ruby dynamic typing
6. **Performance**: BEAM VM > Rails concurrency model

### Pattern Translation

| Rails | Phoenix/Ash |
|-------|-------------|
| ActiveRecord | Ash.Resource |
| ActiveJob | Oban.Worker |
| Controller | LiveView |
| ERB | HEEx |
| Sidekiq cron | Oban cron |

---

## Common Questions

### Q: Why 4 domains instead of 5?

**A**: Merging Clients + Bookings into single Bookings domain reduces complexity, improves cohesion (inseparable workflows), and enhances performance (fewer cross-domain queries). See `domain-architecture-4domains.md` for full rationale.

### Q: What gets tested vs what doesn't?

**A**: Test PilatesOnPhx business logic (custom validations, policies, actions, workflows). Don't test Ash framework features (basic CRUD, sorting, pagination). Target: 85%+ coverage on business logic. See `linear-issue-template.md` Testing Strategy section.

### Q: How do I create a Linear issue for Phoenix/Ash?

**A**: Use `linear-issue-template.md` every time. Include:
- Required metadata (Priority, Labels, Project)
- User story with persona
- Use cases (Happy/Edge/Error in Gherkin)
- Acceptance criteria
- Complete Phoenix/Ash implementation details
- Testing strategy

### Q: What are the required metadata fields?

**A**: MUST set:
- Priority (Critical/High/Medium/Low/Todo)
- Labels (at least one: feature, bug, enhancement)
- Project (Sprint 1/2/3/4 project)

SHOULD set:
- Milestone (Sprint X milestone)
- Parent (Epic ID if story under epic)

DO NOT set:
- Assignee (leave for team lead)
- Cycle (leave for sprint planning)

### Q: Where do I find Phoenix/Ash patterns?

**A**: 
- `/Users/wlstory/src/PilatesOnPhx/AGENTS.md` - Phoenix/Ash patterns
- `/Users/wlstory/src/PilatesOnPhx/CLAUDE.md` - Project conventions
- `linear-issue-template.md` - Implementation examples

### Q: How do I extract requirements from Wlstory/Rails teams?

**A**: Follow `requirements-extraction-guide.md` Phase 1 and Phase 2. Use paginated Linear queries (batches of 20) by feature area. Key issues already identified: WLS-101, WLS-97, WLS-98, WLS-99, WLS-100, WLS-108, WLS-116, WLS-126.

---

## Document Maintenance

### When to Update

- **domain-architecture-4domains.md**: When adding new domains or resources
- **sprint-planning-epics.md**: When creating new epics or adjusting sprint scope
- **linear-issue-template.md**: When adding new patterns or improving template
- **requirements-extraction-guide.md**: When refining extraction methodology
- **EXECUTIVE-SUMMARY.md**: When major project changes occur

### Version Control

All product management docs are version-controlled in the main repository under `/docs/product-management/`. Use meaningful commit messages when updating.

---

## Related Documentation

### Project Documentation

- `/Users/wlstory/src/PilatesOnPhx/README.md` - Project overview and setup
- `/Users/wlstory/src/PilatesOnPhx/CLAUDE.md` - Project conventions for Claude Code
- `/Users/wlstory/src/PilatesOnPhx/AGENTS.md` - Phoenix/Elixir/Ash patterns

### Linear Resources

- Linear Workspace: [Your workspace URL]
- AltBuild-PHX Team: [Team URL]
- Wlstory Team: [Team URL]
- AltBuild-Rails Team: [Team URL]

---

## Contact

For questions about product management documentation:

- **Product Manager**: catalio-product-manager agent
- **Technical Lead**: [Name]
- **Stakeholder Contact**: [Name]

---

## License

Copyright 2025 PilatesOnPhx. All rights reserved.

