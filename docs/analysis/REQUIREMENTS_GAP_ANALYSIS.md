# Phoenix Rewrite Requirements Gap Analysis

**Date**: 2025-11-11
**Analyst**: Claude Code
**Comparison**: Phoenix (44 issues) vs NextJS (120-125 issues) vs Rails (121 issues)

---

## Executive Summary

The Phoenix rewrite currently tracks **44 issues** in Linear compared to **120-125 issues** for NextJS and **121 issues** for Rails rewrites. This represents a **~65% gap** or approximately **76-81 missing issues**.

### Critical Finding

**Sprint 1 has NO child user stories**: The 8 Sprint 1 epics (PHX-1 through PHX-8) are architectural/foundational but have zero implementation stories. NextJS breaks each domain setup into multiple granular stories.

### Root Causes of the Gap

1. **Missing Sprint 1 breakdown**: 0 stories created (should be ~20-25 stories)
2. **Sprint 2 documented but not created**: 22 stories documented but not in Linear
3. **Missing granular sub-tasks**: Phoenix stories lack 2-4 sub-tasks per story
4. **Missing feature categories**: Entire sections absent from Phoenix backlog
5. **Incomplete Sprint 3-4 breakdown**: Only epics created, no child stories

---

## 1. Sprint 1 Breakdown Gap

### Current State
- **8 Epics Created**: PHX-1 through PHX-8 (architectural only)
- **0 Child Stories**: No implementation tasks

### NextJS Equivalent

NextJS breaks each domain setup into 3-4 implementation stories:

| Phoenix Epic | NextJS Stories | Count |
|--------------|----------------|-------|
| PHX-2: Accounts Domain | WLS-60, WLS-135, WLS-124, WLS-108 | 4 |
| PHX-3: Studios Domain | WLS-77, WLS-102 | 2 |
| PHX-4: Classes Domain | WLS-97, WLS-85 | 2 |
| PHX-9: Bookings Domain | WLS-67, WLS-71, WLS-98, WLS-100 | 4 |

### Missing Stories for Sprint 1

Each Phoenix epic should break down into:

#### PHX-2: Accounts Domain → Missing 4 stories
- User resource implementation with AshAuthentication
- Organization multi-tenancy setup
- Token management implementation
- Database migrations for accounts tables

#### PHX-3: Studios Domain → Missing 3 stories
- Studio resource with settings
- Room resource with equipment relationships
- Database migrations for studios tables

#### PHX-4: Classes Domain → Missing 4 stories
- ClassType resource definition
- ClassSchedule recurring pattern logic
- ClassSession with capacity tracking
- Database migrations for classes tables

#### PHX-5: Define Class Resources → Missing 3 stories
- ClassSession CRUD operations
- Capacity calculation logic
- Real-time availability tracking

#### PHX-6: Establish Cross-Domain Relationships → Missing 2 stories
- Define and test cross-domain belongs_to relationships
- Implement and test relationship loading

#### PHX-7: Authorization Policies → Missing 4 stories
- Owner policy implementation
- Instructor policy implementation
- Client policy implementation
- Policy testing suite

#### PHX-8: Multi-Tenant Isolation → Missing 3 stories
- Tenant filter implementation
- RLS policies (optional)
- Cross-tenant access prevention tests

#### PHX-9: Bookings Domain → Missing 5 stories
- Client resource with preferences
- Package and ClientPackage resources
- Booking resource with atomic operations
- Waitlist resource with promotion logic
- Payment resource stub

**Total Missing Sprint 1 Stories: ~28 stories**

---

## 2. Sprint 2 Stories Gap

### Current State
- **3 Epics Created**: PHX-10, PHX-11, PHX-12 (parent epics only)
- **22 Stories Documented**: In `/docs/product-management/SPRINT_2_ISSUES_TO_CREATE.md`
- **0 Stories Created in Linear**: Need to be created

### Documented But Not Created

#### PHX-10: Studio Onboarding (7 child stories)
- PHX-13: Studio Basic Information Capture
- PHX-14: Owner Account Initial Setup
- PHX-15: Business Model Selection
- PHX-16: Studio Configuration Settings
- PHX-17: Class Types Setup
- PHX-18: Rooms & Facilities Management
- PHX-19: Equipment Inventory (Optional)

#### PHX-11: Class Scheduling (5 child stories)
- PHX-20: Create Single Class Session
- PHX-21: Recurring Class Series Creation
- PHX-22: Edit Recurring Class Series
- PHX-23: Cancel/Delete Recurring Series
- PHX-24: Class Calendar View

#### PHX-12: Booking Workflow (9 child stories)
- PHX-25: Client Registration & Profile
- PHX-26: Package Purchase with Stripe
- PHX-27: Browse Available Classes
- PHX-28: Book Class with Credits
- PHX-29: Join Waitlist When Full
- PHX-30: Cancel Booking
- PHX-31: Staff Batch Check-In
- PHX-32: Package Conversion Request
- PHX-33: Attendance Tracking

**Total Sprint 2 Gap: 21 stories documented but not created**

---

## 3. Missing Granularity Per Story

### NextJS Pattern (Example: WLS-102)

WLS-102 "Studio Basic Information Capture" includes:
1. Form field implementation
2. Validation logic
3. File upload for logo
4. Color picker integration
5. Database migration
6. API endpoint
7. UI component
8. Tests

### Phoenix Pattern (Current)

Phoenix stories are at epic level without sub-tasks. Each story should break into:

**Example: PHX-13 "Studio Basic Information Capture"**

Should have 4 sub-tasks:
- [ ] Database migration for studio fields
- [ ] Ash resource create action with validations
- [ ] LiveView component with form
- [ ] Test suite (85%+ coverage)

### Missing Sub-tasks Across All Stories

- **Sprint 2**: 21 stories × 3 sub-tasks = **~63 sub-tasks missing**
- **Sprint 3**: 15 stories × 3 sub-tasks = **~45 sub-tasks missing**
- **Sprint 4**: 15 stories × 3 sub-tasks = **~45 sub-tasks missing**

**Total Missing Sub-tasks: ~153 (if tracked as separate issues)**

---

## 4. Missing Feature Categories

Comparing Phoenix to NextJS WLS issues, these entire feature areas are missing:

### A. Data Migration & Gap Analysis (WLS-110, WLS-112, WLS-116)

**NextJS has 3 dedicated issues**:
- WLS-110: Data migration from legacy system
- WLS-112: Migration validation and reconciliation
- WLS-116: Gap analysis and feature parity tracking

**Phoenix equivalent**: 0 issues

**Recommendation**: Add 3 issues
- PHX-XX: Data Migration Planning
- PHX-XX: Legacy Data Import
- PHX-XX: Migration Validation Suite

### B. Granular Onboarding Steps (WLS-102, WLS-108, WLS-120, WLS-124)

**NextJS has 7 individual onboarding stories**:
- WLS-102: Basic studio info
- WLS-108: Business model selection
- WLS-120: Class types setup
- WLS-121: Rooms setup
- WLS-124: Owner account preferences
- WLS-126: Post-onboarding dashboard configuration
- WLS-135: Authentication setup

**Phoenix equivalent**: 1 epic (PHX-10) with 7 child stories documented but not created

**Status**: Documented in SPRINT_2_ISSUES_TO_CREATE.md but needs Linear creation

### C. Individual Feature Stories vs Epic-Only

**NextJS granular stories Phoenix lacks**:

| Feature | NextJS Issues | Phoenix Issues |
|---------|---------------|----------------|
| Cancel Booking | WLS-67 (granular) | Part of PHX-12 epic |
| Check-In | WLS-71 (granular) | Part of PHX-12 epic |
| Recurring Classes | WLS-97 (detailed) | PHX-11 epic only |
| Cancel Series | WLS-85 (granular) | Part of PHX-11 epic |
| Package Conversion | WLS-98 (detailed) | Part of PHX-12 epic |
| Scheduled Reports | WLS-99 (detailed) | PHX-13 epic only |
| Studio Config | WLS-100 (granular) | Part of PHX-10 epic |

**Recommendation**: Break epics into individual feature stories (already documented in Sprint 2/3/4 files)

### D. Sprint 3-4 Child Stories

**Current State**:
- PHX-12, PHX-13, PHX-14, PHX-15 (epics created)
- Child stories documented in `/docs/product-management/SPRINT_3_4_BACKLOG_ISSUES.md`
- **0 child stories created in Linear**

**Documented Stories**:

#### PHX-12 (Reminder System): 7 child stories
- PHX-23: 24-Hour Class Reminder Job
- PHX-24: 2-Hour Class Reminder Job
- PHX-25: Client Reminder Preferences Management
- PHX-26: Reminder Delivery Tracking & Logging
- (3 more for email/SMS integration)

#### PHX-13 (Scheduled Reports): 7 child stories
- PHX-27: Scheduled Report Configuration UI
- PHX-28: Financial Summary Report Generation
- PHX-29: Class Attendance & Utilization Report
- PHX-30: Package Usage & Expiration Report
- PHX-31-33: PDF, CSV, Email delivery

#### PHX-14 (Recurring Automation): 5 child stories
- PHX-34: Weekly Class Generation Job
- PHX-35: Conflict Detection
- PHX-36: Studio Closure Date Management
- PHX-37-38: Summary email, manual overrides

#### PHX-15 (Stripe Payments): 6 child stories
- PHX-40: Stripe Account Setup
- PHX-41: Payment Intent Creation
- PHX-42: Stripe Elements Payment Form
- PHX-43: Payment Confirmation & Package Activation
- PHX-44: Webhook Handler
- PHX-45: Refund Processing

**Total Sprint 3-4 Gap: ~30 stories documented but not created**

### E. Testing & Quality Stories

**NextJS has explicit testing stories**:
- Integration test suites
- E2E test scenarios
- Performance testing
- Security audits

**Phoenix equivalent**: Testing mentioned in DoD but not tracked as separate issues

**Recommendation**: Consider tracking major test suites as separate issues

### F. Production Readiness

**Missing from Phoenix backlog**:
- Deployment automation stories
- Monitoring and alerting setup
- Error tracking integration (Sentry)
- Performance optimization stories
- Security hardening checklist
- Backup and disaster recovery
- Database optimization and indexing

**Recommendation**: Add ~5-8 production readiness stories

---

## 5. Sprint 3-4 Breakdown Status

### Sprint 3 - Automation & Background Jobs

**Created in Linear**:
- PHX-12: Epic - Email & SMS Reminder System
- PHX-13: Epic - Scheduled Reports & Analytics
- PHX-14: Epic - Recurring Class Automation

**Child Stories Status**:
- **19 stories documented** in SPRINT_3_4_BACKLOG_ISSUES.md
- **0 stories created in Linear**

### Sprint 4 - Integrations & Advanced Features

**Created in Linear**:
- PHX-15: Epic - Stripe Payment Processing

**Child Stories Status**:
- **6 stories documented** for Stripe (PHX-40 through PHX-45)
- **0 stories created in Linear**
- Additional epics documented but not created:
  - PHX-16: Advanced Analytics
  - PHX-17: Mobile PWA Features

---

## 6. Issue Count Breakdown

### By Sprint

| Sprint | Epics Created | Child Stories Created | Child Stories Documented | Total Gap |
|--------|---------------|----------------------|-------------------------|-----------|
| Sprint 1 | 8 | 0 | 0 | **~28 stories** |
| Sprint 2 | 3 | 0 | 22 | **22 stories** |
| Sprint 3 | 3 | 0 | 19 | **19 stories** |
| Sprint 4 | 1 | 0 | 6 | **~15 stories** |
| **Totals** | **15 epics** | **0 stories** | **47 stories** | **~84 stories** |

### Current Linear Status (44 total issues)

**Created**:
- 1 Done (PHX-1)
- 43 Backlog (epics and high-level stories)

**Missing**:
- ~28 Sprint 1 implementation stories
- 22 Sprint 2 stories (documented but not created)
- 19 Sprint 3 stories (documented but not created)
- 15 Sprint 4 stories (partially documented)

**Total Gap: ~84 issues**

### Target State

To match NextJS/Rails (120-125 issues):

**Phoenix should have**:
- 44 current issues
- 84 missing issues
- **= 128 total issues**

This would put Phoenix **ahead** of NextJS/Rails due to more granular breakdown.

**Realistic target** (matching Rails' 121 issues):
- 44 current issues
- 77 additional issues needed
- **= 121 total issues**

---

## 7. Remediation Plan

### Phase 1: Sprint 1 Breakdown (Priority: URGENT)
**Timeline**: Immediate
**Effort**: 2-3 hours

Create **~28 implementation stories** as children of PHX-1 through PHX-9:

1. For each epic (PHX-2, PHX-3, PHX-4, etc.)
2. Create 3-4 child stories covering:
   - Resource implementation
   - Database migrations
   - Testing suite
   - Documentation

**Outcome**: Sprint 1 has executable, granular stories

### Phase 2: Create Sprint 2 Stories (Priority: HIGH)
**Timeline**: This week
**Effort**: 2 hours

**Action**: Copy/paste 22 stories from `/docs/product-management/SPRINT_2_ISSUES_TO_CREATE.md` into Linear

Stories ready to create:
- PHX-13 through PHX-33 (21 stories)
- All have complete specifications
- All have acceptance criteria
- All have Phoenix/Elixir/Ash implementation details

**Outcome**: Sprint 2 backlog is complete and ready for work

### Phase 3: Create Sprint 3 Stories (Priority: MEDIUM)
**Timeline**: Next week
**Effort**: 2 hours

**Action**: Copy/paste stories from `/docs/product-management/SPRINT_3_4_BACKLOG_ISSUES.md` into Linear

Stories ready to create:
- PHX-23 through PHX-38 (~15 stories)
- Covers reminders, reports, and recurring automation

**Outcome**: Sprint 3 backlog is complete

### Phase 4: Create Sprint 4 Stories (Priority: MEDIUM)
**Timeline**: Next week
**Effort**: 1 hour

**Action**: Create remaining Sprint 4 stories

Stories needed:
- PHX-40 through PHX-45 (Stripe - 6 stories)
- Additional analytics and PWA stories (~10 stories)

**Outcome**: Sprint 4 backlog is complete

### Phase 5: Add Production Readiness Stories (Priority: LOW)
**Timeline**: End of month
**Effort**: 1 hour

Create **8-10 production readiness stories**:
- Deployment automation
- Monitoring setup
- Error tracking
- Performance optimization
- Security hardening
- Backup procedures

**Outcome**: Production deployment is tracked and planned

### Phase 6: Add Data Migration Stories (Priority: MEDIUM)
**Timeline**: Before development starts
**Effort**: 1 hour

Create **3 migration stories**:
- PHX-XX: Data Migration Planning
- PHX-XX: Legacy Data Import Implementation
- PHX-XX: Migration Validation & Reconciliation

**Outcome**: Legacy data migration is tracked

---

## 8. Comparison by Feature Area

### Authentication & User Management

| NextJS | Rails | Phoenix |
|--------|-------|---------|
| 6 issues | 6 issues | **1 epic (PHX-2)** + 0 child stories |
| WLS-60, WLS-108, WLS-120, WLS-124, WLS-135 | ALT-41, ALT-42, ALT-4, ALT-5, ALT-6 | **Need: 4 implementation stories** |

**Gap**: 4-5 stories

### Studio & Organization Setup

| NextJS | Rails | Phoenix |
|--------|-------|---------|
| 7 issues | 5 issues | **1 epic (PHX-3)** + 0 child stories |
| WLS-101, WLS-102, WLS-77, etc. | ALT-7, ALT-8, ALT-9 | **Need: 3 implementation stories** |

**Gap**: 3-4 stories

### Class Scheduling

| NextJS | Rails | Phoenix |
|--------|-------|---------|
| 7 issues | 7 issues | **2 epics (PHX-4, PHX-11)** + 5 documented stories |
| WLS-97, WLS-85, etc. | ALT-13, ALT-14, ALT-15, etc. | **Need: Create 5 stories in Linear** |

**Gap**: 0 stories (documented, need creation)

### Booking Workflow

| NextJS | Rails | Phoenix |
|--------|-------|---------|
| 10 issues | 9 issues | **2 epics (PHX-9, PHX-12)** + 9 documented stories |
| WLS-67, WLS-71, WLS-98, etc. | ALT-19, ALT-20, ALT-21, etc. | **Need: Create 9 stories in Linear** |

**Gap**: 0 stories (documented, need creation)

### Automation & Background Jobs

| NextJS | Rails | Phoenix |
|--------|-------|---------|
| 12 issues | 10 issues | **3 epics (PHX-12, PHX-13, PHX-14)** + 19 documented stories |
| WLS-99, etc. | ALT-31, ALT-32, etc. | **Need: Create 19 stories in Linear** |

**Gap**: 0 stories (documented, need creation)

### Payments & Stripe

| NextJS | Rails | Phoenix |
|--------|-------|---------|
| 8 issues | 6 issues | **1 epic (PHX-15)** + 6 documented stories |
| WLS-98 breakdown | ALT-37, ALT-38 breakdown | **Need: Create 6 stories in Linear** |

**Gap**: 0 stories (documented, need creation)

### Analytics & Reporting

| NextJS | Rails | Phoenix |
|--------|-------|---------|
| 10 issues | 8 issues | **1 epic (PHX-16)** + 5 planned stories |
| WLS-99, WLS-116 breakdown | ALT-43, ALT-44 breakdown | **Need: Spec and create 5 stories** |

**Gap**: 5 stories

### Mobile & PWA

| NextJS | Rails | Phoenix |
|--------|-------|---------|
| 5 issues | 4 issues | **1 epic (PHX-17)** + 5 planned stories |
| PWA stories | Mobile stories | **Need: Spec and create 5 stories** |

**Gap**: 5 stories

### Data Migration

| NextJS | Rails | Phoenix |
|--------|-------|---------|
| 3 issues | 2 issues | **0 issues** |
| WLS-110, WLS-112, WLS-116 | Migration stories | **Need: Create 3 stories** |

**Gap**: 3 stories

### Production Readiness

| NextJS | Rails | Phoenix |
|--------|-------|---------|
| 8 issues | 6 issues | **0 issues** |
| Deployment, monitoring, etc. | Deployment stories | **Need: Create 8 stories** |

**Gap**: 8 stories

---

## 9. Recommended Issue Creation Priority

### Immediate (This Week)

1. **Sprint 1 Implementation Stories** (~28 stories)
   - Break down PHX-2, PHX-3, PHX-4, PHX-5, PHX-6, PHX-7, PHX-8, PHX-9
   - Without these, Sprint 1 has no executable work

2. **Sprint 2 Stories** (22 stories)
   - Already fully documented
   - Copy/paste from SPRINT_2_ISSUES_TO_CREATE.md
   - Required for next development phase

### Near Term (Next Week)

3. **Sprint 3 Stories** (19 stories)
   - Already documented in SPRINT_3_4_BACKLOG_ISSUES.md
   - Automation and background jobs

4. **Sprint 4 Stripe Stories** (6 stories)
   - Critical for revenue
   - Already documented

### Later (This Month)

5. **Data Migration Stories** (3 stories)
   - Required before production cutover

6. **Production Readiness Stories** (8 stories)
   - Deployment, monitoring, security

7. **Additional Sprint 4 Stories** (10 stories)
   - Analytics, PWA features

---

## 10. Final Statistics

### Current State
- **Phoenix**: 44 issues (15 epics, 29 high-level stories)
- **NextJS**: 120-125 issues (granular breakdown)
- **Rails**: 121 issues (granular breakdown)

### Missing from Phoenix
- **Sprint 1 breakdown**: 28 stories
- **Sprint 2 (documented)**: 22 stories
- **Sprint 3 (documented)**: 19 stories
- **Sprint 4 (partial)**: 15 stories
- **Data migration**: 3 stories
- **Production readiness**: 8 stories

### Total Gap
- **Documented but not created**: 47 stories
- **Need to spec and create**: 34 stories
- **Total missing**: **~81 stories**

### Target State
- **Current**: 44 issues
- **Add documented stories**: +47 issues = 91 issues
- **Add new stories**: +34 issues = **125 total issues**

**Result**: Phoenix would match NextJS/Rails at **~125 issues**

---

## 11. Conclusion

The Phoenix rewrite is **65% complete** in terms of issue tracking but **only at the epic level**. The gap is not missing features but **missing granular breakdown** of epics into executable stories.

### Key Actions Required

1. **Create ~28 Sprint 1 implementation stories** (URGENT)
2. **Create 47 documented Sprint 2-4 stories** (HIGH priority)
3. **Spec and create 34 additional stories** (MEDIUM priority)

### Timeline to Close Gap
- **Immediate** (this week): 50 stories created from documentation
- **Near-term** (next 2 weeks): 34 additional stories spec'd and created
- **Total effort**: ~8-10 hours of Linear data entry

### Why This Matters

Without granular stories:
- **Sprint planning is impossible** (can't estimate or assign epics)
- **Progress tracking is unclear** (epics stay "in progress" for weeks)
- **Dependencies are hidden** (can't track blockers between stories)
- **Testing is untracked** (no separate test completion tracking)

**Recommendation**: Prioritize Phase 1 and Phase 2 of remediation plan to close the gap within 1 week.

---

**Analysis completed**: 2025-11-11
**Next review**: After Sprint 1-2 story creation
**Document owner**: Product Management / AltBuild-PHX Team
