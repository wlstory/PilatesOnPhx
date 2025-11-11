# Linear Issue Creation Guide

## Overview

This guide provides step-by-step instructions for creating Linear issues from the Sprint 2-4 roadmap.

## Prerequisites

- Access to Linear workspace
- AltBuild-PHX team created in Linear
- Permission to create projects and issues

## Step 1: Create Sprint Projects

Create three new projects in Linear:

### Project 1: Sprint 2 - LiveView Interfaces & User Workflows
- **Description**: Deliver client-facing and staff-facing real-time interfaces for core booking and management workflows
- **Status**: Planned
- **Target Start**: After Sprint 1 completion
- **Duration**: 2-3 weeks

### Project 2: Sprint 3 - Background Jobs & Automations
- **Description**: Implement automated workflows using Oban and AshOban for notifications, recurring tasks, and system maintenance
- **Status**: Planned
- **Target Start**: After Sprint 2 completion
- **Duration**: 2-3 weeks

### Project 3: Sprint 4 - Integrations & Advanced Features
- **Description**: Integrate third-party services for payments, communications, and calendar features. Add advanced functionality for production readiness
- **Status**: Planned
- **Target Start**: After Sprint 3 completion
- **Duration**: 2-3 weeks

## Step 2: Create Issue Labels

Create the following labels in Linear (if not already present):

- `feature` - New feature implementation
- `enhancement` - Enhancement to existing feature
- `liveview` - Phoenix LiveView related
- `background-job` - Oban background job
- `integration` - Third-party integration
- `payment` - Payment processing
- `notification` - Email/SMS notifications
- `analytics` - Analytics and reporting
- `mobile` - Mobile app related
- `high-priority` - High business value
- `dependencies` - Has dependencies on other issues

## Step 3: Create Linear Issues

For each issue in the roadmap (`SPRINT_2_3_4_ROADMAP.md`), create a Linear issue with the following structure:

### Issue Template

**Title**: [Copy from roadmap]

**Description**:
```
[User Story from roadmap]

## Context
[Description paragraph from roadmap]

[Full use cases section from roadmap]
```

**Acceptance Criteria**:
[Copy numbered list from roadmap]

**Technical Implementation**:
[Copy entire Technical Implementation Details section from roadmap]

**Supporting Documentation**:
[Copy from roadmap]

**Dependencies**:
[List Sprint 1 dependencies and any Sprint 2/3 dependencies]

**Estimate**: [Story points from roadmap]

### Issue Metadata

For each issue, set:

- **Project**: Assign to appropriate Sprint project (2, 3, or 4)
- **Team**: AltBuild-PHX
- **Priority**: 
  - Urgent: PHX-9, PHX-10
  - High: PHX-11, PHX-12, PHX-15, PHX-21
  - Medium: PHX-13, PHX-16, PHX-17, PHX-22, PHX-23, PHX-25
  - Low: PHX-14, PHX-18, PHX-19, PHX-20, PHX-24, PHX-26
- **Labels**: Add relevant labels (feature, liveview, background-job, etc.)
- **Estimate**: Set story points from roadmap
- **Status**: Todo (or Backlog)

### Sprint 2 Issues (6 issues, 50 story points)

1. **PHX-9: Class Browse & Search Interface** (5 pts)
   - Priority: Urgent
   - Labels: feature, liveview, high-priority
   - Dependencies: PHX-2, PHX-4
   - Project: Sprint 2

2. **PHX-10: Class Booking Workflow with Real-Time Validation** (8 pts)
   - Priority: Urgent
   - Labels: feature, liveview, high-priority
   - Dependencies: PHX-2, PHX-4, PHX-5
   - Project: Sprint 2

3. **PHX-11: Client Dashboard with Bookings & Credits** (8 pts)
   - Priority: High
   - Labels: feature, liveview
   - Dependencies: PHX-4, PHX-5, PHX-3
   - Project: Sprint 2

4. **PHX-12: Instructor Dashboard with Class Management** (8 pts)
   - Priority: High
   - Labels: feature, liveview
   - Dependencies: PHX-2, PHX-4, PHX-7
   - Project: Sprint 2

5. **PHX-13: Owner/Admin Dashboard with Analytics** (13 pts)
   - Priority: Medium
   - Labels: feature, liveview, analytics
   - Dependencies: All Sprint 1 resources
   - Project: Sprint 2

6. **PHX-14: User Profile Management** (8 pts)
   - Priority: Low
   - Labels: feature, liveview
   - Dependencies: PHX-1
   - Project: Sprint 2

### Sprint 3 Issues (6 issues, 68 story points)

1. **PHX-15: Class Reminder Notification System** (13 pts)
   - Priority: High
   - Labels: feature, background-job, notification, high-priority
   - Dependencies: PHX-4, PHX-3, External services (Twilio, Resend/SendGrid)
   - Project: Sprint 3

2. **PHX-16: Waitlist Promotion Automation** (13 pts)
   - Priority: Medium
   - Labels: feature, background-job
   - Dependencies: PHX-4, PHX-6, PHX-5
   - Project: Sprint 3

3. **PHX-17: Recurring Class Generation** (13 pts)
   - Priority: Medium
   - Labels: feature, background-job
   - Dependencies: PHX-2, PHX-7, PHX-8
   - Project: Sprint 3

4. **PHX-18: Package Expiration Warnings** (8 pts)
   - Priority: Low
   - Labels: feature, background-job, notification
   - Dependencies: PHX-5, PHX-3
   - Project: Sprint 3

5. **PHX-19: Attendance Tracking Automation** (8 pts)
   - Priority: Low
   - Labels: feature, background-job
   - Dependencies: PHX-4, PHX-3, PHX-8
   - Project: Sprint 3

6. **PHX-20: Report Generation System** (13 pts)
   - Priority: Low
   - Labels: feature, background-job, analytics
   - Dependencies: All Sprint 1-2 resources
   - Project: Sprint 3

### Sprint 4 Issues (6 issues, 63 story points)

1. **PHX-21: Stripe Payment Integration** (13 pts)
   - Priority: High
   - Labels: feature, integration, payment, high-priority
   - Dependencies: PHX-5, External service (Stripe)
   - Project: Sprint 4

2. **PHX-22: Resend/SendGrid Email Service Integration** (8 pts)
   - Priority: Medium
   - Labels: feature, integration, notification
   - Dependencies: All features sending emails (PHX-15, PHX-16, PHX-18, etc.)
   - Project: Sprint 4

3. **PHX-23: Twilio SMS Integration** (8 pts)
   - Priority: Medium
   - Labels: feature, integration, notification
   - Dependencies: PHX-15, PHX-16, PHX-14
   - Project: Sprint 4

4. **PHX-24: Calendar Integration (iCal Export)** (8 pts)
   - Priority: Low
   - Labels: feature, integration
   - Dependencies: PHX-4, PHX-3
   - Project: Sprint 4

5. **PHX-25: Analytics Dashboard & Reporting** (13 pts)
   - Priority: Medium
   - Labels: feature, liveview, analytics
   - Dependencies: All Sprint 1-3 resources
   - Project: Sprint 4

6. **PHX-26: Mobile App Support (PWA/Capacitor)** (13 pts)
   - Priority: Low
   - Labels: feature, mobile
   - Dependencies: All Sprint 1-3 features
   - Project: Sprint 4

## Step 4: Set Up Issue Dependencies in Linear

After creating all issues, link dependencies:

1. Open each issue in Linear
2. In the "Relates to" or "Dependencies" section, add links to prerequisite issues
3. Mark as "Blocked by" for hard dependencies

## Step 5: Create Milestones (Optional)

Create milestones to group related work:

### Milestone 1: Core Booking Experience
- PHX-9: Class Browse & Search Interface
- PHX-10: Class Booking Workflow
- PHX-11: Client Dashboard

### Milestone 2: Staff Tools
- PHX-12: Instructor Dashboard
- PHX-13: Owner/Admin Dashboard
- PHX-14: User Profile Management

### Milestone 3: Automation & Notifications
- PHX-15: Class Reminder Notification System
- PHX-16: Waitlist Promotion Automation
- PHX-18: Package Expiration Warnings
- PHX-19: Attendance Tracking Automation

### Milestone 4: Business Operations
- PHX-17: Recurring Class Generation
- PHX-20: Report Generation System
- PHX-25: Analytics Dashboard

### Milestone 5: Payment & Integrations
- PHX-21: Stripe Payment Integration
- PHX-22: Email Service Integration
- PHX-23: SMS Integration
- PHX-24: Calendar Integration

### Milestone 6: Mobile & Advanced Features
- PHX-26: Mobile App Support

## Step 6: Validate Issue Creation

After creating all issues, verify:

- [ ] All 18 issues created (PHX-9 through PHX-26)
- [ ] Each issue has correct project assignment
- [ ] Each issue has appropriate priority
- [ ] Each issue has relevant labels
- [ ] Each issue has story point estimate
- [ ] Dependencies are linked in Linear
- [ ] All issues assigned to AltBuild-PHX team
- [ ] Milestones created (optional)

## Automation Tips

If using Linear API or CLI:

```bash
# Example: Create issue via Linear CLI
linear issue create \
  --title "Class Browse & Search Interface" \
  --description "$(cat issue_description.md)" \
  --project "Sprint 2 - LiveView Interfaces" \
  --team "AltBuild-PHX" \
  --priority "Urgent" \
  --estimate 5 \
  --label "feature" \
  --label "liveview" \
  --label "high-priority"
```

## Next Steps After Issue Creation

1. **Sprint Planning**: Review and prioritize issues within each sprint
2. **Team Assignment**: Assign specific developers to issues
3. **Cycle Planning**: Add issues to active cycles when ready to start
4. **Backlog Grooming**: Refine estimates and acceptance criteria as needed
5. **Requirements Extraction**: Extract additional requirements from NextJS and Rails teams
6. **Dependency Mapping**: Ensure all dependencies from Sprint 1 are linked

## Contact

For questions about issue creation or roadmap clarification, contact the Product Manager or BSA.

---

**Last Updated**: 2025-11-10
