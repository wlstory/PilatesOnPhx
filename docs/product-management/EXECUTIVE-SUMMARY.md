# PilatesOnPhx Product Management - Executive Summary

**Date**: 2025-11-10
**Author**: catalio-product-manager agent
**Project**: PilatesOnPhx Phoenix/Elixir/Ash Rewrite
**Teams**: NextJS (Wlstory), Rails (AltBuild-Rails), Phoenix (AltBuild-PHX)

---

## Mission Statement

Extract comprehensive requirements from NextJS (Wlstory) and Rails (AltBuild-Rails) teams and translate them into well-structured Linear user stories for the Phoenix/Elixir/Ash (AltBuild-PHX) rewrite, leveraging the strengths of the Phoenix/Ash ecosystem while maintaining feature parity and improving on the original implementations.

---

## Architecture Decision: 4-Domain Strategic Design

### Decision Summary

The PilatesOnPhx architecture has been simplified from **5 domains to 4 strategic domains** to optimize for cohesion, reduce cross-domain complexity, and align with core business workflows.

### Domain Structure

```elixir
config :pilates_on_phx, :ash_domains, [
  PilatesOnPhx.Accounts,  # Authentication & Multi-Tenant Foundation
  PilatesOnPhx.Studios,   # Studio Management & Configuration
  PilatesOnPhx.Classes,   # Class Management + Scheduling + Attendance + Instructors
  PilatesOnPhx.Bookings   # THE CORE WORKFLOW: Client + Package + Booking + Waitlist
]
```

### Key Change

**Merged**: `Clients` domain + `Bookings` domain → Single `Bookings` domain

**Rationale**: 
- Client and booking operations are inseparable in practice
- Atomic operations (credit deduction + booking creation)
- Reduced cross-domain queries
- Natural workflow aggregation

### Benefits

- **Reduced Complexity**: 20% fewer domain boundaries
- **Improved Cohesion**: Complete workflows in single domain
- **Better Performance**: Fewer cross-domain queries
- **Clearer Ownership**: Unambiguous feature placement

---

## Sprint Planning Overview

### Sprint 1: Foundation (2 weeks)

**Goal**: Establish 4-domain architecture with core resources and multi-tenant policies

**Issues**: PHX-1 through PHX-8 (with PHX-5+6 merged)

**Key Deliverables**:
- 4-domain architecture documented and approved
- Core resources defined for all domains
- Multi-tenant policies implemented
- Testing strategy established
- Database schema migrated

**Success Criteria**:
- All domains have basic CRUD operations
- Multi-tenant isolation enforced
- 85%+ test coverage on business logic
- `mix precommit` passes cleanly

---

### Sprint 2: Core Workflows (3 weeks)

**Goal**: Implement essential user-facing workflows for MVP

**Epics**: 3 major epics, 19+ user stories

#### Epic PHX-9: Studio Onboarding & Setup (6 stories)
- **Business Value**: First-run experience determines retention
- **Stories**: PHX-10 through PHX-15
- **Workflow**: 6-step wizard (Studio Info → Business Model → Staff → Class Types → Schedule → Launch)
- **Priority**: Critical (MVP blocker)

#### Epic PHX-16: Class Scheduling & Recurring Classes (5 stories)
- **Business Value**: Core scheduling enables operations
- **Stories**: PHX-17 through PHX-21
- **Features**: Single sessions, recurring templates, Oban generation, editing, substitutions
- **Priority**: Critical (MVP blocker)

#### Epic PHX-22: Booking Workflow & Package Management (8 stories)
- **Business Value**: THE CORE REVENUE-GENERATING WORKFLOW
- **Stories**: PHX-23 through PHX-30
- **Workflow**: Client Registration → Browse Classes → Purchase Package → Book → Waitlist → Cancel → Expiration → Admin Dashboard
- **Priority**: Critical (MVP blocker)

**Success Criteria**:
- Studio owners complete onboarding end-to-end
- Instructors create recurring schedules
- Clients book classes with credit redemption
- Waitlist auto-promotion works
- All workflows have 85%+ test coverage

---

### Sprint 3: Automation & Advanced Features (3 weeks)

**Goal**: Add background job automation and advanced UX

**Epics**: 3 major epics, 13+ user stories

#### Epic PHX-31: Attendance & Check-In System (4 stories)
- **Business Value**: Track attendance, enforce no-show policies
- **Stories**: PHX-32 through PHX-35
- **Features**: Front desk check-in, mobile check-in, no-show detection, attendance reports
- **Priority**: High

#### Epic PHX-36: Automation & Background Jobs (5 stories)
- **Business Value**: Reduce manual work, improve client experience
- **Stories**: PHX-37 through PHX-41
- **Features**: Nightly session generation (Oban), email reminders, SMS reminders (Twilio), scheduled reports, expiration notifications
- **Priority**: High

#### Epic PHX-42: Client & Instructor Dashboards (4 stories)
- **Business Value**: Improve UX with personalized views
- **Stories**: PHX-43 through PHX-46
- **Features**: Client dashboard, booking history, instructor dashboard, class rosters
- **Priority**: Medium

**Success Criteria**:
- Recurring sessions generated automatically every night
- Reminders sent 24h before classes
- Attendance tracked with no-show penalties
- Dashboards personalized per role

---

### Sprint 4: Integrations & Polish (3 weeks)

**Goal**: Add payment processing, reporting, and mobile PWA

**Epics**: 3 major epics, 15+ user stories

#### Epic PHX-47: Payments & Stripe Integration (6 stories)
- **Business Value**: Enable real payment processing
- **Stories**: PHX-48 through PHX-53
- **Features**: Stripe Connect setup, credit card payments, recurring billing, refunds, invoices, payment history
- **Priority**: High

#### Epic PHX-54: Reporting & Analytics (5 stories)
- **Business Value**: Business intelligence for studio owners
- **Stories**: PHX-55 through PHX-59
- **Features**: Revenue reports, attendance reports, retention metrics, instructor performance, custom report builder
- **Priority**: Medium

#### Epic PHX-60: Mobile PWA & Advanced UX (4 stories)
- **Business Value**: Mobile-first experience for clients
- **Stories**: PHX-61 through PHX-64
- **Features**: PWA installation, push notifications, biometric auth, mobile-optimized UI
- **Priority**: Medium

**Success Criteria**:
- Stripe payments processing successfully
- Financial and attendance reports generated
- Mobile PWA installable on iOS/Android
- Production-ready quality across all features

---

## Total Scope

### Summary Statistics

| Metric | Value |
|--------|-------|
| **Total Sprints** | 4 (11 weeks) |
| **Total Epics** | 9+ |
| **Total User Stories** | 55+ |
| **Domains** | 4 (Accounts, Studios, Classes, Bookings) |
| **Test Coverage Target** | 85%+ |
| **Success Rate Target** | 90%+ issue completion |

### Domain Distribution

| Domain | Estimated Stories | Percentage |
|--------|------------------|------------|
| Accounts | 5-7 | ~10% |
| Studios | 12-15 | ~25% |
| Classes | 15-18 | ~30% |
| Bookings | 18-22 | ~35% |

### Sprint Distribution

| Sprint | Focus | Stories | Duration |
|--------|-------|---------|----------|
| Sprint 1 | Foundation | 8 | 2 weeks |
| Sprint 2 | Core Workflows | 19+ | 3 weeks |
| Sprint 3 | Automation | 13+ | 3 weeks |
| Sprint 4 | Integrations | 15+ | 3 weeks |

---

## Requirements Extraction Strategy

### Source Teams

#### NextJS (Wlstory Team)
- **Stack**: React, Next.js, Supabase, TypeScript
- **Key Issues**: WLS-101 (Onboarding), WLS-97 (Recurring), WLS-98 (Packages), WLS-99 (Reports), WLS-100 (Config), WLS-108 (Owner Setup), WLS-116 (Gap Analysis), WLS-126 (Feature Parity)
- **Extraction Method**: Paginated queries (batches of 20) by feature area
- **Coverage Target**: 100% of critical requirements

#### Rails (AltBuild-Rails Team)
- **Stack**: Ruby on Rails, ActiveRecord, Sidekiq, PostgreSQL
- **Key Patterns**: ActiveRecord → Ash Resources, ActiveJob → Oban, Controllers → LiveView
- **Extraction Method**: Paginated queries focusing on models, workers, views
- **Coverage Target**: 100% of critical requirements

### Translation Methodology

**Rails → Phoenix/Ash Mapping**:

| Rails Pattern | Phoenix/Ash Equivalent |
|---------------|------------------------|
| `ActiveRecord::Base` | `use Ash.Resource` |
| `belongs_to :studio` | `belongs_to :studio, Studios.Studio` |
| `validates :name, presence: true` | `validate present([:name])` |
| `after_create :send_email` | `change after_action(&send_email/2)` |
| `ActiveJob` | `use Oban.Worker` |
| Controller action | LiveView event handler |
| ERB template | HEEx template |
| Sidekiq cron | Oban cron schedule |

---

## Quality Standards

### Every Linear Issue Must Have

1. **Clear Business Value**: Why does this feature matter?
2. **Complete User Story**: "As a [role], I want [action], so that [benefit]"
3. **Multiple Use Cases**: Happy path + edge cases + error cases (Gherkin format)
4. **Testable Acceptance Criteria**: Specific, measurable, achievable
5. **Detailed Implementation**: Ash resources, actions, LiveView, Oban jobs
6. **Testing Strategy**: 85%+ coverage on business logic
7. **Dependencies**: Blocking and related issues identified
8. **Required Metadata**: Priority, labels, project, milestone

### Red Flags (Must Avoid)

- ❌ Vague user stories without clear actors or benefits
- ❌ Missing use cases (especially error cases)
- ❌ No Phoenix/Ash implementation details
- ❌ Untestable acceptance criteria
- ❌ Missing dependencies
- ❌ No priority set
- ❌ No project assignment

### Quality Gates

Before creating any issue:

- [ ] User story adds clear business value
- [ ] Acceptance criteria are testable
- [ ] Technical feasibility verified
- [ ] No duplicate issues exist
- [ ] Requirements align with 4-domain architecture
- [ ] Testing strategy defined
- [ ] Dependencies identified

---

## Phoenix/Elixir/Ash Advantages

### Why Phoenix/Ash for This Rewrite?

1. **Declarative Resource Management**:
   - Ash resources replace verbose ActiveRecord models
   - Actions, validations, and policies in single file
   - Less boilerplate than Rails

2. **Built-in Multi-Tenant Support**:
   - Ash policies enforce studio isolation
   - Actor-based authorization out of the box
   - No need for manual tenant scoping

3. **Real-Time by Default**:
   - LiveView for instant UI updates
   - Phoenix PubSub for real-time events
   - No need for Action Cable complexity

4. **Concurrent Background Jobs**:
   - Oban leverages Elixir concurrency
   - Reliable job processing with Postgres-backed queues
   - Better than Sidekiq/Redis for this use case

5. **Type Safety & Reliability**:
   - Elixir's pattern matching reduces bugs
   - Ash's type system catches errors at compile time
   - Dialyzer for additional type checking

6. **Performance**:
   - Elixir's BEAM VM handles concurrency better than Rails
   - Lower memory footprint
   - Better handling of WebSocket connections

---

## Implementation Patterns

### Core Patterns from AGENTS.md

1. **Ash Resources**: Declarative domain models
2. **LiveView**: Real-time UI without JavaScript complexity
3. **Oban Workers**: Reliable background job processing
4. **Phoenix PubSub**: Real-time event broadcasting
5. **Multi-Tenant Policies**: Studio-level data isolation
6. **Actor-Based Authorization**: Every operation requires actor

### Testing Philosophy

**Test What PilatesOnPhx Does, Not What Ash Does**:

✅ **DO TEST**:
- Custom validations (business rules)
- Authorization policies (multi-tenant security)
- Domain-specific actions (`book_class`, `cancel_booking`)
- Complex workflows (booking with credit deduction)
- Edge cases and error handling

❌ **DON'T TEST**:
- Basic CRUD (Ash handles this)
- Sorting/filtering (framework feature)
- Pagination (framework feature)
- Timestamps (framework feature)
- Standard validations (framework feature)

**Target**: 85%+ coverage on business logic

---

## Documentation Deliverables

### Product Management Docs (Created)

1. **domain-architecture-4domains.md** - Complete 4-domain design with rationale
2. **sprint-planning-epics.md** - Full epic and user story breakdown
3. **linear-issue-template.md** - Comprehensive template for all Phoenix/Ash stories
4. **requirements-extraction-guide.md** - Step-by-step extraction methodology
5. **EXECUTIVE-SUMMARY.md** - This document

### Location

All documentation in: `/Users/wlstory/src/PilatesOnPhx/docs/product-management/`

---

## Next Steps

### Immediate Actions (Product Manager)

1. **Review Architecture**: Approve 4-domain design
2. **Query Wlstory Issues**: Extract all NextJS requirements
3. **Query Rails Issues**: Extract all Rails requirements
4. **Create Epics**: Set up 9+ epics in Linear (AltBuild-PHX)
5. **Create User Stories**: Generate 55+ stories using template
6. **Set Up Projects**: Create Linear projects for 4 sprints
7. **Set Up Milestones**: Create milestones for grouping
8. **Assign Priorities**: Prioritize all issues
9. **Generate Report**: Create final coverage report

### Development Team Actions

1. **Review Sprint 1 Issues**: Understand foundation work (PHX-1 through PHX-8)
2. **Set Up Linear**: Ensure team has access to AltBuild-PHX project
3. **Review Documentation**: Read CLAUDE.md and AGENTS.md
4. **Prepare Environment**: Set up Phoenix dev environment
5. **Begin Sprint 1**: Start with domain architecture (PHX-1)

### Stakeholder Actions

1. **Approve Architecture**: Sign off on 4-domain design
2. **Review Sprint Plan**: Approve 11-week roadmap
3. **Allocate Resources**: Assign developers to AltBuild-PHX team
4. **Set Expectations**: Align on MVP scope (Sprint 2 deliverables)
5. **Define Success Metrics**: Agree on KPIs for each sprint

---

## Risk Mitigation

### Identified Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Incomplete Requirements** | High | 100% coverage verification before Sprint 2 |
| **Cross-Domain Complexity** | Medium | 4-domain design reduces complexity |
| **Phoenix/Ash Learning Curve** | Medium | Comprehensive AGENTS.md documentation |
| **Testing Coverage** | Medium | 85%+ target enforced via quality gates |
| **Scope Creep** | High | Strict sprint boundaries, no mid-sprint additions |

### Success Factors

- ✅ Clear domain boundaries (4 domains)
- ✅ Comprehensive requirements extraction
- ✅ Detailed user stories with implementation plans
- ✅ 85%+ test coverage target
- ✅ Quality gates before issue creation
- ✅ Sprint-based delivery with clear milestones

---

## Success Criteria

### Sprint 1 Success
- [ ] All 4 domains defined with core resources
- [ ] Multi-tenant policies implemented
- [ ] 85%+ test coverage on business logic
- [ ] Database schema migrated
- [ ] `mix precommit` passes

### Sprint 2 Success
- [ ] Studio owners complete onboarding wizard
- [ ] Instructors create recurring schedules
- [ ] Clients book classes with packages
- [ ] Waitlist auto-promotion works
- [ ] All critical workflows tested

### Sprint 3 Success
- [ ] Recurring sessions generated nightly (Oban)
- [ ] Email/SMS reminders sent
- [ ] Attendance tracked with no-show handling
- [ ] Dashboards personalized per role

### Sprint 4 Success
- [ ] Stripe payments processing
- [ ] Financial and attendance reports generated
- [ ] Mobile PWA installable
- [ ] Production deployment ready

### Overall Project Success
- [ ] 100% of MVP features delivered
- [ ] 85%+ test coverage maintained
- [ ] 90%+ issue completion rate
- [ ] < 10% technical debt
- [ ] Production-ready quality
- [ ] Feature parity with NextJS/Rails versions
- [ ] Improved performance over Rails version

---

## Conclusion

This comprehensive product management package provides everything needed to successfully extract requirements from NextJS (Wlstory) and Rails (AltBuild-Rails) teams and translate them into well-structured Phoenix/Elixir/Ash user stories for the AltBuild-PHX team.

The 4-domain architecture provides a solid foundation, the sprint plan delivers value incrementally, and the quality standards ensure production-ready code.

With 9 epics, 55+ user stories, and 11 weeks of planned work, PilatesOnPhx is positioned to become a best-in-class Pilates studio management system built on modern Phoenix/Elixir/Ash technology.

---

**Questions or Clarifications?**

Contact the catalio-product-manager agent for any questions about requirements extraction, user story creation, or Linear issue templates.

**Documentation References**:
- `/Users/wlstory/src/PilatesOnPhx/CLAUDE.md` - Project conventions
- `/Users/wlstory/src/PilatesOnPhx/AGENTS.md` - Phoenix/Ash patterns
- `/Users/wlstory/src/PilatesOnPhx/README.md` - Project overview
- `/Users/wlstory/src/PilatesOnPhx/docs/product-management/` - All PM docs

