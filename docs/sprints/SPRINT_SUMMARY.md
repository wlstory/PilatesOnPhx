# PilatesOnPhx - Sprint 2, 3, 4 Summary

## Quick Stats

- **Total Issues**: 18 (PHX-9 through PHX-26)
- **Total Story Points**: 181
- **Sprints**: 3 (each 2-3 weeks)
- **Team**: AltBuild-PHX

## Sprint Breakdown

### Sprint 2: LiveView Interfaces & User Workflows
**Goal**: Real-time booking and management interfaces

- **6 issues, 50 story points**
- **Priority**: High (Core user experience)
- **Key Technologies**: LiveView, LiveView Streams, PubSub

| Issue ID | Title | Points | Priority |
|----------|-------|--------|----------|
| PHX-9 | Class Browse & Search Interface | 5 | Urgent |
| PHX-10 | Class Booking Workflow | 8 | Urgent |
| PHX-11 | Client Dashboard | 8 | High |
| PHX-12 | Instructor Dashboard | 8 | High |
| PHX-13 | Owner/Admin Dashboard | 13 | Medium |
| PHX-14 | User Profile Management | 8 | Low |

### Sprint 3: Background Jobs & Automations
**Goal**: Automated workflows and notifications

- **6 issues, 68 story points**
- **Priority**: High (Essential automations)
- **Key Technologies**: Oban, AshOban, Email/SMS APIs

| Issue ID | Title | Points | Priority |
|----------|-------|--------|----------|
| PHX-15 | Class Reminder Notifications | 13 | High |
| PHX-16 | Waitlist Promotion Automation | 13 | Medium |
| PHX-17 | Recurring Class Generation | 13 | Medium |
| PHX-18 | Package Expiration Warnings | 8 | Low |
| PHX-19 | Attendance Tracking Automation | 8 | Low |
| PHX-20 | Report Generation System | 13 | Low |

### Sprint 4: Integrations & Advanced Features
**Goal**: Third-party integrations and production readiness

- **6 issues, 63 story points**
- **Priority**: Medium (Production polish)
- **Key Technologies**: Stripe, Resend/SendGrid, Twilio, PWA

| Issue ID | Title | Points | Priority |
|----------|-------|--------|----------|
| PHX-21 | Stripe Payment Integration | 13 | High |
| PHX-22 | Email Service Integration | 8 | Medium |
| PHX-23 | Twilio SMS Integration | 8 | Medium |
| PHX-24 | Calendar Integration (iCal) | 8 | Low |
| PHX-25 | Analytics Dashboard & Reporting | 13 | Medium |
| PHX-26 | Mobile App Support (PWA) | 13 | Low |

## Priority Distribution

- **Urgent**: 2 issues (13 points) - PHX-9, PHX-10
- **High**: 3 issues (34 points) - PHX-11, PHX-12, PHX-15, PHX-21
- **Medium**: 6 issues (72 points) - PHX-13, PHX-16, PHX-17, PHX-22, PHX-23, PHX-25
- **Low**: 7 issues (62 points) - PHX-14, PHX-18, PHX-19, PHX-20, PHX-24, PHX-26

## Technology Stack Highlights

### Phoenix/Elixir/Ash Advantages

1. **LiveView**: Real-time UIs without JavaScript complexity
   - Used in: PHX-9, PHX-10, PHX-11, PHX-12, PHX-13, PHX-14, PHX-25

2. **Oban + AshOban**: Reliable background job processing
   - Used in: PHX-15, PHX-16, PHX-17, PHX-18, PHX-19, PHX-20

3. **Ash Framework**: Declarative business logic
   - Actions, calculations, aggregates, policies across all issues

4. **Phoenix PubSub**: Real-time broadcasts
   - Used in: PHX-9, PHX-10, PHX-11, PHX-12, PHX-13

### External Services

- **Stripe** (PHX-21): Payment processing
- **Resend/SendGrid** (PHX-22): Transactional emails
- **Twilio** (PHX-23): SMS notifications
- **Cloud Storage** (PHX-14): Profile photos and reports

## Key Features by User Role

### Client Features
- Browse and book classes with real-time availability (PHX-9, PHX-10)
- Personal dashboard with bookings and credits (PHX-11)
- Profile management with photo upload (PHX-14)
- Automated reminders and notifications (PHX-15, PHX-18)
- Waitlist with auto-promotion (PHX-16)
- Mobile app support (PWA) (PHX-26)
- Package purchases via Stripe (PHX-21)
- Calendar export (PHX-24)

### Instructor Features
- Class roster and attendance tracking (PHX-12)
- Real-time booking updates (PHX-12)
- Class management interface (PHX-12)

### Studio Owner Features
- Admin dashboard with analytics (PHX-13)
- Monthly business reports (PHX-20)
- Advanced analytics with custom reports (PHX-25)
- Staff management (PHX-13)
- Recurring class templates (PHX-17)
- Payment tracking (PHX-21)

### System Features
- Automated class reminders (PHX-15)
- Waitlist promotion automation (PHX-16)
- Recurring class generation (PHX-17)
- Package expiration warnings (PHX-18)
- No-show tracking (PHX-19)
- Email/SMS integrations (PHX-22, PHX-23)

## Critical Paths

### Path 1: Core Booking Flow (Must Have)
PHX-9 → PHX-10 → PHX-11

**Why**: Essential for clients to book classes and manage their schedule.

### Path 2: Staff Tools (Must Have)
PHX-12 → PHX-13

**Why**: Instructors and owners need tools to manage operations.

### Path 3: Automation (Should Have)
PHX-15 → PHX-16 → PHX-17

**Why**: Reduces manual work and improves client experience.

### Path 4: Payment (Must Have for Revenue)
PHX-21

**Why**: Required for monetization and package purchases.

### Path 5: Communication (Should Have)
PHX-22 → PHX-23

**Why**: Reliable email/SMS delivery improves client engagement.

## Risk Mitigation

### Technical Risks

1. **Real-time Performance** (PHX-9, PHX-10)
   - Mitigation: LiveView streams, PubSub optimization, database indexes

2. **Concurrent Bookings** (PHX-10)
   - Mitigation: Database transactions, optimistic locking, unique constraints

3. **Background Job Reliability** (PHX-15-20)
   - Mitigation: Oban retry logic, error handling, admin alerts

4. **External Service Downtime** (PHX-21-23)
   - Mitigation: Retry logic, fallback mechanisms, graceful degradation

### Business Risks

1. **Payment Processing** (PHX-21)
   - Mitigation: Stripe's proven reliability, webhook validation, reconciliation

2. **Email Deliverability** (PHX-22)
   - Mitigation: Reputable provider (Resend/SendGrid), bounce handling, verification

3. **SMS Costs** (PHX-23)
   - Mitigation: Opt-in only, rate limiting, cost tracking

## Success Metrics

### Sprint 2 Success Criteria
- [ ] Clients can browse and book classes end-to-end
- [ ] Real-time availability updates work correctly
- [ ] All dashboards (client, instructor, owner) are functional
- [ ] 85%+ test coverage on booking flow
- [ ] Mobile responsive on all key pages

### Sprint 3 Success Criteria
- [ ] Automated reminders sent 24h and 2h before classes
- [ ] Waitlist promotion happens automatically on cancellation
- [ ] Recurring classes generate weekly without manual intervention
- [ ] All background jobs have retry logic and monitoring
- [ ] Admin dashboard shows job status and failures

### Sprint 4 Success Criteria
- [ ] Stripe payments work end-to-end (test mode)
- [ ] Email delivery rate >95%
- [ ] SMS delivery rate >90%
- [ ] PWA installable on mobile devices
- [ ] Analytics dashboard shows real-time metrics
- [ ] Calendar export works with major calendar apps

## Timeline Estimate

- **Sprint 1**: Complete (PHX-1 through PHX-8) - Foundation
- **Sprint 2**: Weeks 1-3 - Core UI and booking flow
- **Sprint 3**: Weeks 4-6 - Automation and notifications
- **Sprint 4**: Weeks 7-9 - Integrations and production polish
- **Total Duration**: 9 weeks (2.25 months)

## Next Actions

1. [ ] Create 3 sprint projects in Linear
2. [ ] Create all 18 issues in Linear
3. [ ] Set priorities and labels
4. [ ] Link dependencies between issues
5. [ ] Assign to AltBuild-PHX team
6. [ ] Create milestones (optional)
7. [ ] Extract additional requirements from NextJS team (Wlstory)
8. [ ] Extract additional requirements from Rails team (AltBuild-Rails)
9. [ ] Conduct sprint planning session
10. [ ] Begin Sprint 2 development

## Resources

- **Full Roadmap**: `/docs/sprints/SPRINT_2_3_4_ROADMAP.md`
- **Linear Creation Guide**: `/docs/sprints/LINEAR_ISSUE_CREATION_GUIDE.md`
- **Project Documentation**: `/CLAUDE.md`, `/AGENTS.md`, `/README.md`

---

**Created**: 2025-11-10  
**Team**: AltBuild-PHX  
**Product Manager**: catalio-product-manager agent
