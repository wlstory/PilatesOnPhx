# Sprint 2 Issues - Creation Summary

**Date**: 2025-11-11
**Status**: ✅ Complete - All 23 issues created in Linear
**Project**: Sprint 2 - Core User Workflows (ID: 9f2b68bd-c266-4da0-b220-bd05196f3124)
**Team**: AltBuild-PHX

---

## Summary Statistics

- **Total Issues Created**: 23 (1 epic + 22 user stories)
- **Epic**: 1
- **User Stories**: 22
- **Priority Urgent (1)**: 19 issues
- **Priority High (2)**: 4 issues
- **Time to Create**: ~3 minutes (all in single session)

---

## Epic Created

### PHX-46: Booking Workflow & Package Management
- **Type**: Epic
- **Priority**: Urgent (1)
- **URL**: https://linear.app/wlstory/issue/PHX-46
- **Children**: 9 user stories (PHX-59 to PHX-67)
- **Status**: Backlog

**Note**: This epic was intended to be PHX-12 but Linear auto-assigned PHX-46 based on current issue count.

---

## User Stories Created

### Onboarding Workflow (Parent: PHX-10) - 7 Stories

#### PHX-47: Studio Basic Information Capture (Onboarding Step 1)
- **Priority**: Urgent (1)
- **URL**: https://linear.app/wlstory/issue/PHX-47
- **Key Features**: Form validation, logo upload, brand color picker
- **Domain**: Studios

#### PHX-48: Owner Account Initial Setup (Onboarding Step 2)
- **Priority**: Urgent (1)
- **URL**: https://linear.app/wlstory/issue/PHX-48
- **Key Features**: AshAuthentication, OAuth (Google), database trigger for org/studio creation
- **Domain**: Accounts

#### PHX-49: Business Model Selection (Onboarding Step 3)
- **Priority**: Urgent (1)
- **URL**: https://linear.app/wlstory/issue/PHX-49
- **Key Features**: Standard vs Contract Labor model, feature flag configuration
- **Domain**: Studios
- **Critical**: This selection drives entire revenue model

#### PHX-50: Studio Configuration Settings (Onboarding Step 4)
- **Priority**: Urgent (1)
- **URL**: https://linear.app/wlstory/issue/PHX-50
- **Key Features**: Timezone, first day of week, cancellation policy
- **Domain**: Studios

#### PHX-51: Class Types Setup (Onboarding Step 5)
- **Priority**: Urgent (1)
- **URL**: https://linear.app/wlstory/issue/PHX-51
- **Key Features**: Create class types with defaults (Reformer, Mat, Private)
- **Domain**: Classes

#### PHX-52: Rooms & Facilities Management (Onboarding Step 6)
- **Priority**: Urgent (1)
- **URL**: https://linear.app/wlstory/issue/PHX-52
- **Key Features**: Create rooms, assign class types, set capacity
- **Domain**: Studios

#### PHX-53: Equipment Inventory (Optional Onboarding Step)
- **Priority**: High (2)
- **URL**: https://linear.app/wlstory/issue/PHX-53
- **Key Features**: Add equipment, set rental fees, can skip
- **Domain**: Studios

---

### Class Scheduling (Parent: PHX-11) - 5 Stories

#### PHX-54: Create Single Class Session
- **Priority**: High (2)
- **URL**: https://linear.app/wlstory/issue/PHX-54
- **Key Features**: Create individual class, conflict detection
- **Domain**: Classes

#### PHX-55: Recurring Class Series Creation
- **Priority**: High (2)
- **URL**: https://linear.app/wlstory/issue/PHX-55
- **Key Features**: Daily/weekly/monthly patterns, Oban background job
- **Domain**: Classes

#### PHX-56: Edit Recurring Class Series
- **Priority**: High (2)
- **URL**: https://linear.app/wlstory/issue/PHX-56
- **Key Features**: Edit scope (this/following/all), preserve bookings
- **Domain**: Classes

#### PHX-57: Cancel/Delete Recurring Series
- **Priority**: High (2)
- **URL**: https://linear.app/wlstory/issue/PHX-57
- **Key Features**: Cancellation scope, refund bookings, notify clients
- **Domain**: Classes

#### PHX-58: Class Calendar View with Real-Time Updates
- **Priority**: High (2)
- **URL**: https://linear.app/wlstory/issue/PHX-58
- **Key Features**: Weekly/monthly views, PubSub real-time updates, filters
- **Domain**: Classes

---

### Booking Workflow (Parent: PHX-46) - 9 Stories

#### PHX-59: Client Registration & Profile Setup
- **Priority**: Urgent (1)
- **URL**: https://linear.app/wlstory/issue/PHX-59
- **Key Features**: Client registration, emergency contact, preferences
- **Domain**: Bookings

#### PHX-60: Package Purchase with Stripe Integration
- **Priority**: Urgent (1)
- **URL**: https://linear.app/wlstory/issue/PHX-60
- **Key Features**: Stripe Elements, Payment Intent, 3D Secure, credit allocation
- **Domain**: Bookings
- **External**: Stripe API (stripity_stripe)

#### PHX-61: Browse Available Classes with Real-Time Capacity
- **Priority**: Urgent (1)
- **URL**: https://linear.app/wlstory/issue/PHX-61
- **Key Features**: Class browser, real-time capacity via PubSub, filters
- **Domain**: Bookings

#### PHX-62: Book Class with Package Credits (Atomic Operation)
- **Priority**: Urgent (1)
- **URL**: https://linear.app/wlstory/issue/PHX-62
- **Key Features**: **ATOMIC TRANSACTION** (deduct credit + create booking), race condition prevention
- **Domain**: Bookings
- **Critical**: THE MOST CRITICAL FEATURE - Revenue Core Workflow

#### PHX-63: Join Waitlist When Class Full
- **Priority**: Urgent (1)
- **URL**: https://linear.app/wlstory/issue/PHX-63
- **Key Features**: Auto-join waitlist, position tracking, promotion on cancellation
- **Domain**: Bookings

#### PHX-64: Cancel Booking with Policy-Based Refund
- **Priority**: Urgent (1)
- **URL**: https://linear.app/wlstory/issue/PHX-64
- **Key Features**: Policy-based refunds, early vs late cancellation, waitlist promotion
- **Domain**: Bookings

#### PHX-65: Staff Batch Check-In Interface
- **Priority**: Urgent (1)
- **URL**: https://linear.app/wlstory/issue/PHX-65
- **Key Features**: Batch check-in, roster display, attendance tracking
- **Domain**: Bookings

#### PHX-66: Package Conversion Request & Approval
- **Priority**: High (2)
- **URL**: https://linear.app/wlstory/issue/PHX-66
- **Key Features**: Conversion requests, owner approval, price difference handling
- **Domain**: Bookings

#### PHX-67: Attendance Tracking & Reports
- **Priority**: High (2)
- **URL**: https://linear.app/wlstory/issue/PHX-67
- **Key Features**: Attendance history, no-show tracking, CSV export
- **Domain**: Bookings

---

## Issue Breakdown by Domain

### Accounts Domain (1 story)
- PHX-48: Owner Account Initial Setup

### Studios Domain (4 stories)
- PHX-47: Studio Basic Information Capture
- PHX-49: Business Model Selection
- PHX-50: Studio Configuration Settings
- PHX-52: Rooms & Facilities Management
- PHX-53: Equipment Inventory

### Classes Domain (6 stories)
- PHX-51: Class Types Setup
- PHX-54: Create Single Class Session
- PHX-55: Recurring Class Series Creation
- PHX-56: Edit Recurring Class Series
- PHX-57: Cancel/Delete Recurring Series
- PHX-58: Class Calendar View

### Bookings Domain (10 stories + 1 epic)
- PHX-46: Booking Workflow & Package Management (Epic)
- PHX-59: Client Registration & Profile
- PHX-60: Package Purchase with Stripe
- PHX-61: Browse Available Classes
- PHX-62: Book Class with Credits (CRITICAL)
- PHX-63: Join Waitlist
- PHX-64: Cancel Booking
- PHX-65: Staff Batch Check-In
- PHX-66: Package Conversion Request
- PHX-67: Attendance Tracking

---

## Technical Implementation Highlights

### Key Technologies
- **Ash Framework 3.0+**: Declarative resource definitions, actions, validations
- **AshAuthentication**: User registration, OAuth providers
- **Phoenix LiveView**: Real-time UI, PubSub updates
- **Oban**: Background jobs for recurring class generation, waitlist promotions
- **Stripe**: Payment processing (stripity_stripe)
- **PostgreSQL**: Database triggers for auto-creation of org/studio

### Critical Patterns

#### Atomic Transactions (PHX-62)
```elixir
create :book_class do
  # All changes in single database transaction
  validate validate_sufficient_credits()
  validate validate_class_capacity()
  change deduct_credits()  # Must succeed with booking
  change decrement_capacity()
  change set_attribute(:status, :confirmed)
  change broadcast_capacity_update()
  change send_confirmation()
end
```

#### Real-Time Updates (PHX-58, PHX-61)
```elixir
Phoenix.PubSub.subscribe(PilatesOnPhx.PubSub, "studio:#{studio_id}:classes")

def handle_info({:class_capacity_updated, class_id, new_capacity}, socket) do
  # Update UI in real-time
end
```

#### Policy-Based Logic (PHX-64)
```elixir
def refund_credits_by_policy(changeset) do
  studio = get_studio(changeset)
  hours_until_class = calculate_hours(booking.class_session.scheduled_at)

  if hours_until_class >= studio.late_cancel_hours do
    refund_credits(changeset, booking.credits_used)
  else
    charge_late_cancel_fee(changeset)
  end
end
```

---

## Testing Requirements

All stories include:
- **85%+ code coverage target**
- **LiveViewTest** for UI interactions
- **Integration tests** for cross-domain workflows
- **Ash action tests** for business logic
- **Race condition tests** (PHX-62)
- **Real-time update tests** (PubSub)

### Example Test Strategy (PHX-62)
- Test atomic transaction (all or nothing)
- Test concurrent booking race conditions
- Test insufficient credits error
- Test class full error
- Test confirmation email sent

---

## Dependencies

### External Dependencies
- AshAuthentication package
- Stripe API (stripity_stripe)
- Oban for background jobs
- Phoenix PubSub

### Internal Dependencies
All stories depend on Sprint 1 foundation:
- PHX-2: Accounts Domain
- PHX-3: Studios Domain
- PHX-4: Classes Domain
- PHX-9: Bookings Domain

---

## Critical Path

1. **Foundation** (Sprint 1 must be complete)
2. **Onboarding** (PHX-47 → PHX-48 → PHX-49 → PHX-50 → PHX-51 → PHX-52)
3. **Scheduling** (PHX-54 → PHX-55 → PHX-58)
4. **Booking Core** (PHX-59 → PHX-60 → PHX-61 → **PHX-62** → PHX-63 → PHX-64)
5. **Operations** (PHX-65 → PHX-67)

**PHX-62 (Book Class with Credits)** is the most critical feature - the entire revenue workflow depends on this atomic operation working correctly.

---

## Success Criteria

### Business Metrics
- 85%+ onboarding completion rate within 7 days
- Median onboarding time < 10 minutes
- 95%+ booking success rate (no race conditions)
- < 2 seconds for booking confirmation
- Stripe payment success rate > 98%
- Waitlist promotion < 5 minutes

### Technical Metrics
- Zero credit leakage (atomic operations)
- Zero race condition bugs
- 85%+ test coverage
- Real-time updates < 1 second

---

## Gap Analysis Update

### Previous Gap (Before Sprint 2 Creation)
- **Total Issues**: 44 (Phoenix) vs 120-125 (NextJS/Rails)
- **Gap**: 65% shortfall

### After Sprint 2 Creation
- **Total Issues**: 67 (44 existing + 23 new)
- **Remaining Gap**: ~58 issues

### Still Needed
1. **Sprint 1 Implementation Stories**: 28 stories (break down 8 epics into executable tasks)
2. **Data Migration Stories**: 3 stories
3. **Production Readiness Stories**: 8 stories
4. **Remaining Sprint 3-4 Backlog**: ~19 stories

**Next Action**: Create 28 Sprint 1 implementation stories to break down the foundation epics.

---

## Files Generated

1. **This Summary**: `/docs/product-management/SPRINT_2_CREATED_SUMMARY.md`
2. **Full Specifications**: `/docs/product-management/SPRINT_2_LINEAR_ISSUES_READY.md` (3,411 lines)
3. **Original Source**: `/docs/product-management/SPRINT_2_ISSUES_TO_CREATE.md`

---

## Linear Dashboard

- **Sprint 2 Project**: https://linear.app/wlstory/project/sprint-2-core-user-workflows-9f2b68bd-c266-4da0-b220-bd05196f3124
- **Team Dashboard**: https://linear.app/wlstory/team/PHX/backlog
- **Epic PHX-46**: https://linear.app/wlstory/issue/PHX-46

---

**Last Updated**: 2025-11-11
**Document Version**: 1.0
**Created By**: Claude Code
