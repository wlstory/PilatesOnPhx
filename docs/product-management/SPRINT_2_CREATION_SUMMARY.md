# Sprint 2 Linear Issues - Creation Summary

**Date**: 2025-11-11
**Status**: ✅ Specifications Complete - Ready for Linear Creation
**Team**: AltBuild-PHX (ID: 6e4b0bca-146e-4a33-8c4a-314f6f7d5834)
**Project**: Sprint 2 - Core User Workflows (ID: 9f2b68bd-c266-4da0-b220-bd05196f3124)

## Overview

Comprehensive specifications have been created for all 23 Sprint 2 issues. Each issue includes:

- ✅ Complete user story (As a [role], I can [action], so that [benefit])
- ✅ Multiple Gherkin use cases (Happy Path, Edge Cases, Error Cases)
- ✅ Detailed acceptance criteria
- ✅ Phoenix/Elixir/Ash implementation details with code examples
- ✅ Testing strategy (targeting 85%+ coverage)
- ✅ Dependencies and blockers
- ✅ Definition of Done checklist
- ✅ File references with specific line numbers

## Issues Breakdown

### Epic (1)
- **PHX-12**: Booking Workflow & Package Management
  - Priority: 1 (Urgent)
  - Labels: epic, booking, core-workflow, sprint-2, critical
  - Parent: None
  - Children: 9 stories (PHX-25 to PHX-33)

### Onboarding Stories (7) - Parent: PHX-10
All Priority 1 (Urgent)

1. **PHX-13**: Studio Basic Information Capture (Step 1)
   - Form fields, logo upload, color picker
   - Phone/email/URL validation
   - Save & Exit functionality
   - **Original**: WLS-102

2. **PHX-14**: Owner Account Initial Setup (Step 2)
   - AshAuthentication email/password + OAuth
   - Database trigger auto-creates Org + Studio
   - Email verification
   - **Original**: WLS-108, WLS-135

3. **PHX-15**: Business Model Selection (Step 3)
   - Standard Studio vs Contract Labor
   - Feature flags configuration
   - Reporting templates
   - **Original**: WLS-101

4. **PHX-16**: Studio Configuration Settings (Step 4)
   - Timezone, booking window, cancellation policy
   - Business hours per day
   - Settings validation

5. **PHX-17**: Class Types Setup (Step 5)
   - Define class types (Reformer, Mat, etc.)
   - Duration, capacity, equipment
   - Default types option

6. **PHX-18**: Rooms & Facilities Management (Step 6)
   - Room capacity and equipment assignment
   - Photo upload
   - Can skip (single room default)

7. **PHX-19**: Equipment Inventory (Optional Step 6b)
   - Track reformers, mats, props
   - Optional - can be added later
   - Quantity validation

### Scheduling Stories (5) - Parent: PHX-11
All Priority 2 (High)

8. **PHX-20**: Create Single Class Session
   - One-off class scheduling
   - Instructor/room double-booking prevention
   - Outside business hours warning

9. **PHX-21**: Recurring Class Series Creation
   - Daily/Weekly/Monthly patterns
   - Holiday skip option
   - Bulk session generation

10. **PHX-22**: Edit Recurring Class Series
    - Modify time, instructor, room
    - Apply to future-only or all sessions
    - Notification handling

11. **PHX-23**: Cancel/Delete Recurring Series
    - Soft delete (cancel) vs hard delete
    - Refund processing
    - Audit trail

12. **PHX-24**: Class Calendar View
    - Month/Week/Day views
    - Real-time capacity via PubSub
    - Drag-and-drop reschedule

### Booking Workflow Stories (9) - Parent: PHX-12
All Priority 1 (Urgent)

13. **PHX-25**: Client Registration & Profile
    - Email/password authentication
    - Emergency contact, health notes
    - Profile completion
    - **Original**: Extracted from WLS-60

14. **PHX-26**: Package Purchase with Stripe Integration ⭐
    - CRITICAL REVENUE FEATURE
    - Stripe Elements, 3D Secure support
    - Atomic payment + credit allocation
    - **Original**: WLS-98

15. **PHX-27**: Browse Available Classes with Real-Time Capacity
    - Class browser with filters
    - Phoenix PubSub live updates
    - "Full" and "Almost Full" badges
    - **Original**: WLS-60

16. **PHX-28**: Book Class with Package Credits (Atomic Operation) ⭐⭐⭐
    - MOST CRITICAL FEATURE
    - Atomic transaction: credit deduction + booking + capacity
    - Race condition prevention (row-level locking)
    - Database constraint: capacity never negative
    - **Original**: WLS-60

17. **PHX-29**: Join Waitlist When Class Full
    - Auto-join when full
    - Position tracking
    - Auto-promotion on cancellation
    - 24-hour confirmation window
    - **Original**: WLS-60, WLS-67

18. **PHX-30**: Cancel Booking with Policy-Based Refund
    - Cancellation policy calculation
    - Full/partial/no refund based on time
    - Triggers waitlist promotion
    - **Original**: WLS-67

19. **PHX-31**: Staff Batch Check-In Interface
    - Mobile-optimized check-in page
    - Bulk check-in
    - Oban job for no-show marking
    - **Original**: WLS-71

20. **PHX-32**: Package Conversion Request & Approval
    - Client requests conversion
    - Admin review workflow
    - Price adjustment calculation
    - **Original**: WLS-98

21. **PHX-33**: Attendance Tracking & Reports
    - Attendance reports by class/instructor/client
    - No-show rate, average class size
    - CSV export
    - Visual charts

## Critical Path Dependencies

```
PHX-14 (Owner Account)
    ↓
PHX-13 (Studio Info)
    ↓
PHX-15 (Business Model)
    ↓
PHX-16 (Configuration)
    ↓
PHX-17 (Class Types) → PHX-20 (Single Class) → PHX-21 (Recurring) → PHX-24 (Calendar)
    ↓
PHX-18 (Rooms)
    ↓
PHX-25 (Client Registration)
    ↓
PHX-26 (Package Purchase) ⭐ CRITICAL
    ↓
PHX-27 (Browse Classes)
    ↓
PHX-28 (Book Class) ⭐⭐⭐ MOST CRITICAL
    ↓
PHX-29 (Waitlist) ←→ PHX-30 (Cancel Booking)
    ↓
PHX-31 (Check-In)
    ↓
PHX-33 (Attendance Reports)

PHX-32 (Package Conversion) - Independent admin feature
```

## Technical Highlights

### Atomic Transactions
- **PHX-28** (Book Class): Database-level transaction with row-level locking
- **PHX-26** (Package Purchase): Payment + credit allocation atomic
- **PHX-30** (Cancel Booking): Refund + capacity + waitlist promotion atomic

### Real-Time Features (Phoenix PubSub)
- **PHX-27**: Class browser with live capacity updates
- **PHX-24**: Calendar with live class changes
- **PHX-28**: Broadcast capacity changes on booking

### Background Jobs (Oban)
- **PHX-29**: Waitlist expiration job (24-hour window)
- **PHX-31**: No-show marking job (30 min after class end)

### Stripe Integration
- **PHX-26**: Package purchase with 3D Secure
- **PHX-32**: Additional payment for conversions

### Complex Business Logic
- **PHX-28**: Race condition prevention, credit deduction, capacity management
- **PHX-30**: Tiered cancellation policy calculation
- **PHX-21**: Recurring pattern generation (daily/weekly/monthly)
- **PHX-22**: Series edit with future-only vs all-sessions logic

## Testing Requirements

- **All stories**: 85%+ code coverage
- **PHX-28**: 90%+ coverage (critical path) + race condition stress tests
- **Real testing**: No mocking of security, authentication, or database operations
- **Integration tests**: Complete workflows (signup → purchase → book → check-in)
- **LiveViewTest**: For all LiveView interactions
- **Stress testing**: PHX-28 with 100 concurrent bookings

## File Locations

### Primary Documentation
- **Full Specifications**: `/Users/wlstory/src/PilatesOnPhx/docs/product-management/SPRINT_2_LINEAR_ISSUES_READY.md` (3,411 lines)
- **Original Source**: `/Users/wlstory/src/PilatesOnPhx/docs/product-management/SPRINT_2_ISSUES_TO_CREATE.md`
- **This Summary**: `/Users/wlstory/src/PilatesOnPhx/docs/product-management/SPRINT_2_CREATION_SUMMARY.md`

### Related Files
- **AGENTS.md**: Phoenix/Elixir/Ash patterns (lines 450-1500)
- **CLAUDE.md**: Project overview and development guidelines
- **README.md**: Setup and getting started

## Next Steps for Linear Creation

Since Linear MCP tools are not available in this environment, you have several options:

### Option 1: Linear Web UI (Recommended for Bulk Import)
1. Open Linear web interface
2. Navigate to AltBuild-PHX team
3. Use bulk import feature if available
4. Copy/paste from SPRINT_2_LINEAR_ISSUES_READY.md

### Option 2: Linear CLI
```bash
# Install Linear CLI
npm install -g @linear/cli

# Authenticate
linear auth

# Create issues programmatically
linear issue create \
  --team AltBuild-PHX \
  --project "Sprint 2 - Core User Workflows" \
  --title "Booking Workflow & Package Management" \
  --description "$(cat epic_phx12.md)" \
  --priority 1 \
  --label epic,booking,core-workflow
```

### Option 3: Linear API with Script
Create a Node.js or Python script that:
1. Reads SPRINT_2_LINEAR_ISSUES_READY.md
2. Parses each issue section
3. Uses Linear GraphQL API to create issues
4. Handles parent-child relationships

### Option 4: Manual Entry
For highest quality control:
1. Create Epic PHX-12 first (note the ID)
2. Create each child story, setting parentId
3. Use SPRINT_2_LINEAR_ISSUES_READY.md as comprehensive template

## Quality Assurance Checklist

Before creating in Linear, verify:

- [x] All 23 issues have complete specifications
- [x] User stories follow "As a [role], I can [action], so that [benefit]" format
- [x] Each issue has at least 3 use cases (Happy Path, Edge Case, Error Case)
- [x] Acceptance criteria are testable and numbered
- [x] Technical implementation includes code examples
- [x] Testing strategy defined with coverage targets
- [x] Dependencies listed
- [x] Definition of Done included
- [x] Priority assigned (1 for Urgent, 2 for High)
- [x] Labels identified
- [x] Parent epic specified for child stories
- [x] Project ID confirmed (9f2b68bd-c266-4da0-b220-bd05196f3124)
- [x] Team ID confirmed (6e4b0bca-146e-4a33-8c4a-314f6f7d5834)

## Success Metrics

Once all issues are created in Linear:

1. **Total Issues**: 23 (1 epic + 22 stories)
2. **Proper Hierarchy**: All stories linked to parent epics
3. **Project Assignment**: All in "Sprint 2 - Core User Workflows"
4. **Priority Distribution**: 16 Urgent, 5 High
5. **Labels Applied**: All issues have at least one label
6. **Ready for Sprint Planning**: Can be pulled into cycles

## Notes

- These specifications represent production-ready requirements
- Each issue is independently implementable with clear DoD
- Critical path stories (PHX-26, PHX-28) are marked with ⭐
- All technical implementations follow AGENTS.md patterns
- Testing requirements enforce quality standards from CLAUDE.md

---

**Status**: ✅ READY FOR LINEAR CREATION
**Next Action**: Create issues in Linear using method of your choice
**Questions**: Refer to SPRINT_2_LINEAR_ISSUES_READY.md for full details
