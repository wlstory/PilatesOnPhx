# Sprint Planning & Epic Breakdown

## Overview

This document outlines the epic and user story structure for PilatesOnPhx development, organized across 4 sprints. Each epic represents a major feature area with multiple user stories underneath.

---

## Sprint 1: Foundation (Domain Architecture)

**Goal**: Establish 4-domain architecture with core resources and multi-tenant policies.

**Duration**: 2 weeks

**Success Criteria**:
- All 4 domains defined with core resources
- Multi-tenant policies implemented
- Testing strategy documented
- Database schema migrated
- Basic CRUD operations working per domain

### Sprint 1 Issues (Foundation)

#### PHX-1: Design Ash Domain Architecture (4 Domains)
**Type**: Architecture Design
**Priority**: Critical
**Status**: Update Required

**Changes from 5-domain to 4-domain**:
- Merge Clients + Bookings into single Bookings domain
- Update domain descriptions
- Revise resource allocation

#### PHX-2: Define Core Resources for Accounts Domain
**Type**: Feature
**Priority**: Critical
**Resources**: User, Organization, Token

#### PHX-3: Define Core Resources for Studios Domain
**Type**: Feature
**Priority**: Critical
**Resources**: Studio, StudioStaff, Room, Equipment

#### PHX-4: Define Core Resources for Classes Domain
**Type**: Feature
**Priority**: Critical
**Resources**: ClassType, ClassSchedule, ClassSession, Attendance, Instructor

#### PHX-5+6 (MERGED): Define Core Resources for Bookings Domain
**Type**: Feature
**Priority**: Critical
**Resources**: Client, Package, ClientPackage, Booking, Waitlist, Payment

**Merge Rationale**: Client and Booking operations are inseparable in practice.

#### PHX-7: Implement Multi-Tenant Policies Across Domains
**Type**: Feature
**Priority**: Critical
**Updates**: Reflect 4-domain architecture

#### PHX-8: Testing Strategy and Coverage Setup
**Type**: Process
**Priority**: High
**Updates**: Reflect 4-domain architecture

---

## Sprint 2: Core Workflows (MVP Features)

**Goal**: Implement essential user-facing workflows for studio onboarding, class scheduling, and booking.

**Duration**: 3 weeks

**Success Criteria**:
- Studio owners can complete onboarding wizard
- Instructors can create recurring class schedules
- Clients can browse and book classes
- Package purchase and credit tracking working
- Client and instructor dashboards functional

### Epics for Sprint 2

---

### Epic PHX-9: Studio Onboarding & Setup

**Parent**: None
**Priority**: Critical
**Estimated Stories**: 6
**Business Value**: First-run experience determines user retention

**Description**: Multi-step wizard for new studio owners to set up their studio, configure business model, add staff, and create initial class offerings.

**Acceptance Criteria**:
- Studio owners can complete 6-step onboarding wizard
- Onboarding progress is saved between sessions
- Can skip steps and return later
- All required configuration is captured
- Success metrics tracked

**User Stories**:

#### PHX-10: Studio Basic Information Capture
**Source**: WLS-101 (NextJS), WLS-108 (Owner Account Setup)

**User Story**: 
As a studio owner
I want to enter my studio's basic information (name, address, contact)
So that my studio profile is complete and findable

**Use Cases**:
```gherkin
Scenario: [Happy Path] Owner completes basic studio information
  Given I am a newly registered studio owner
  When I navigate to the onboarding wizard
  And I enter studio name "Downtown Pilates"
  And I enter address "123 Main St, Phoenix, AZ"
  And I enter phone "602-555-1234"
  And I enter email "info@downtownpilates.com"
  And I click "Continue"
  Then I see "Step 2: Business Model" screen
  And my studio profile is saved with basic information

Scenario: [Edge Case] Owner skips step and returns later
  Given I am on Step 1 of onboarding
  When I click "Skip for now"
  Then I am taken to Step 2
  And Step 1 is marked as incomplete
  And I can return to Step 1 later via progress indicator

Scenario: [Error Case] Owner submits invalid email
  Given I am on Step 1 of onboarding
  When I enter email "invalid-email"
  And I click "Continue"
  Then I see error "Please enter a valid email address"
  And I remain on Step 1
```

**Acceptance Criteria**:
1. Form captures: name, address, phone, email, website
2. All fields validated before proceeding
3. Progress saved automatically
4. Can skip and return later
5. Studio record created in Studios domain

**Phoenix/Ash Implementation**:

**Domain**: Studios

**Resources**:
- Studios.Studio
  - Action: `:create_from_onboarding`
  - Attributes: name, address, phone, email, website, onboarding_step
  - Validations: email format, phone format, required fields

**LiveView**:
- `PilatesOnPhxWeb.OnboardingLive.StudioInfo`
- Form with `to_form/2` pattern
- Validation on change, submission creates studio
- Progress tracking in session

**Ash Actions**:
```elixir
# lib/pilates_on_phx/studios/studio.ex
create :create_from_onboarding do
  accept [:name, :address, :phone, :email, :website]
  
  argument :owner_id, :uuid, allow_nil?: false
  
  change set_attribute(:onboarding_step, 1)
  change relate_actor(:owner)
  
  validate present([:name, :email])
  validate match(:email, ~r/@/)
end
```

**Testing Strategy**:
- Test create action with valid attributes
- Test validation failures (invalid email, missing name)
- Test actor association (studio belongs to owner)
- LiveViewTest for form submission and validation errors
- 85%+ coverage on business logic

**Dependencies**:
- Accounts.User must exist (owner actor)
- PHX-3 (Studios domain resources)

**References**:
- WLS-101: Studio Onboarding Wizard
- WLS-108: Owner Account Setup
- CLAUDE.md: Lines 113-124 (Domain architecture)

---

#### PHX-11: Business Model Selection
**Source**: WLS-101 Step 2

**User Story**:
As a studio owner
I want to configure my business model (drop-in, packages, memberships)
So that my pricing and booking rules are correctly set up

**Use Cases**:
```gherkin
Scenario: [Happy Path] Owner selects package-based model
  Given I completed Step 1 of onboarding
  When I navigate to Step 2 "Business Model"
  And I select "Package-based (class credits)"
  And I configure default package sizes [5, 10, 20 classes]
  And I set package expiration to "90 days"
  And I click "Continue"
  Then default packages are created for my studio
  And I proceed to Step 3

Scenario: [Edge Case] Owner selects multiple business models
  Given I am on Step 2 "Business Model"
  When I select "Packages" and "Memberships"
  Then both pricing models are enabled
  And I can configure both simultaneously

Scenario: [Error Case] Owner selects no business model
  Given I am on Step 2 "Business Model"
  When I click "Continue" without selecting a model
  Then I see error "Please select at least one business model"
  And I remain on Step 2
```

**Acceptance Criteria**:
1. Can select: Drop-in, Packages, Memberships, or combinations
2. Configuration options shown based on selection
3. Default packages created automatically
4. Studio settings updated with business model
5. Can modify defaults before proceeding

**Phoenix/Ash Implementation**:

**Domain**: Studios, Bookings (for Package templates)

**Resources**:
- Studios.Studio
  - Action: `:configure_business_model`
  - Attributes: `business_model` (enum: :drop_in, :packages, :memberships)
  - Attributes: `package_expiration_days` (integer)

- Bookings.Package (templates)
  - Action: `:create_default_templates`
  - Pre-defined packages: 5-class, 10-class, 20-class, unlimited

**LiveView**:
- `PilatesOnPhxWeb.OnboardingLive.BusinessModel`
- Multi-select form for business models
- Dynamic configuration fields based on selection

**Ash Actions**:
```elixir
# lib/pilates_on_phx/studios/studio.ex
update :configure_business_model do
  accept [:business_model, :package_expiration_days]
  
  argument :create_default_packages, :boolean, default: true
  
  change set_attribute(:onboarding_step, 2)
  
  change fn changeset, _context ->
    if Ash.Changeset.get_argument(changeset, :create_default_packages) do
      # Trigger package template creation
      studio = Ash.Changeset.data(changeset)
      PilatesOnPhx.Bookings.create_default_packages(studio)
    end
    changeset
  end
end
```

**Testing Strategy**:
- Test each business model selection
- Test default package creation
- Test multiple model selection
- Test validation (at least one model required)
- Integration test: studio update + package creation

**Dependencies**:
- PHX-10 (Studio info captured)
- PHX-5+6 (Bookings domain - Package resource)

---

#### PHX-12: Staff and Instructor Setup
**Source**: WLS-101 Step 3

**User Story**:
As a studio owner
I want to add staff members and instructors
So that they can teach classes and manage operations

**Use Cases**:
```gherkin
Scenario: [Happy Path] Owner invites instructor via email
  Given I completed Steps 1-2 of onboarding
  When I navigate to Step 3 "Staff Setup"
  And I enter instructor email "jane@example.com"
  And I assign role "Instructor"
  And I click "Send Invitation"
  Then invitation email is sent to Jane
  And Jane appears in pending staff list
  And I can continue to Step 4

Scenario: [Edge Case] Owner skips staff setup (solo studio)
  Given I am on Step 3 "Staff Setup"
  When I click "Skip - I'll add staff later"
  Then I proceed to Step 4
  And Step 3 is marked as incomplete

Scenario: [Error Case] Owner invites duplicate email
  Given I already invited "jane@example.com"
  When I try to invite "jane@example.com" again
  Then I see error "Jane is already invited or on staff"
  And invitation is not sent
```

**Acceptance Criteria**:
1. Can invite staff via email
2. Can assign roles: Owner, Instructor, Front Desk
3. Invitation emails sent automatically
4. Pending invitations tracked
5. Can skip and add staff later

**Phoenix/Ash Implementation**:

**Domain**: Studios, Accounts

**Resources**:
- Studios.StudioStaff
  - Action: `:invite_staff`
  - Attributes: email, role, invitation_token, invited_at, accepted_at

- Accounts.User
  - Relationship: `has_many :studio_staff, Studios.StudioStaff`

**LiveView**:
- `PilatesOnPhxWeb.OnboardingLive.StaffSetup`
- Form to invite staff
- List of pending and active staff
- Role selector

**Ash Actions**:
```elixir
# lib/pilates_on_phx/studios/studio_staff.ex
create :invite_staff do
  accept [:email, :role]
  
  argument :studio_id, :uuid, allow_nil?: false
  
  change set_attribute(:invitation_token, &generate_token/0)
  change set_attribute(:invited_at, &DateTime.utc_now/0)
  
  validate present([:email, :role])
  validate match(:email, ~r/@/)
  validate one_of(:role, [:owner, :instructor, :front_desk])
  
  # Send invitation email via Oban
  change after_action(&send_invitation_email/2)
end
```

**Oban Job**:
```elixir
# lib/pilates_on_phx/studios/workers/send_staff_invitation.ex
defmodule PilatesOnPhx.Studios.Workers.SendStaffInvitation do
  use Oban.Worker, queue: :mailers
  
  def perform(%{args: %{"staff_id" => staff_id}}) do
    staff = PilatesOnPhx.Studios.get_staff!(staff_id)
    # Send email via Swoosh
    PilatesOnPhxWeb.Emails.StaffInvitation.send(staff)
  end
end
```

**Testing Strategy**:
- Test staff invitation creation
- Test duplicate email validation
- Test role validation
- Test Oban job enqueued
- Integration test: invitation email sent

**Dependencies**:
- PHX-3 (Studios domain - StudioStaff resource)
- PHX-2 (Accounts domain - User)
- Oban configured

---

#### PHX-13: Class Type Definition
**Source**: WLS-101 Step 4

**User Story**:
As a studio owner
I want to define my class types (Reformer, Mat, Barre, etc.)
So that I can schedule classes with proper categorization

**Use Cases**:
```gherkin
Scenario: [Happy Path] Owner creates Reformer class type
  Given I completed Steps 1-3 of onboarding
  When I navigate to Step 4 "Class Types"
  And I click "Add Class Type"
  And I enter name "Reformer - Intermediate"
  And I select category "Reformer"
  And I set duration to 55 minutes
  And I set default capacity to 8
  And I add description "Intermediate level Reformer class"
  And I click "Save Class Type"
  Then "Reformer - Intermediate" appears in class type list
  And I can proceed to Step 5

Scenario: [Edge Case] Owner uses pre-defined templates
  Given I am on Step 4 "Class Types"
  When I click "Use Templates"
  Then I see common class types: Reformer, Mat, Barre, Tower
  And I can select multiple templates to add
  And selected templates are added with default settings

Scenario: [Error Case] Owner creates class type with zero capacity
  Given I am creating a new class type
  When I set capacity to 0
  And I click "Save Class Type"
  Then I see error "Capacity must be at least 1"
  And class type is not saved
```

**Acceptance Criteria**:
1. Can create custom class types
2. Can use pre-defined templates
3. Each type has: name, category, duration, capacity, description
4. Multiple class types can be added
5. Can edit/delete before proceeding

**Phoenix/Ash Implementation**:

**Domain**: Classes

**Resources**:
- Classes.ClassType
  - Action: `:create_from_onboarding`
  - Attributes: name, category, duration_minutes, default_capacity, description
  - Belongs to: Studios.Studio

**LiveView**:
- `PilatesOnPhxWeb.OnboardingLive.ClassTypes`
- Form to create class types
- List of created class types with edit/delete
- Template selector modal

**Ash Actions**:
```elixir
# lib/pilates_on_phx/classes/class_type.ex
create :create_from_onboarding do
  accept [:name, :category, :duration_minutes, :default_capacity, :description]
  
  argument :studio_id, :uuid, allow_nil?: false
  
  change relate_actor(:studio)
  
  validate present([:name, :category, :duration_minutes, :default_capacity])
  validate numericality(:default_capacity, greater_than: 0)
  validate numericality(:duration_minutes, greater_than: 0)
end

# Action to create from templates
create :from_template do
  argument :template_name, :atom, allow_nil?: false
  argument :studio_id, :uuid, allow_nil?: false
  
  change fn changeset, _context ->
    template = get_template(Ash.Changeset.get_argument(changeset, :template_name))
    changeset
    |> Ash.Changeset.change_attributes(template)
  end
end

defp get_template(:reformer), do: %{
  name: "Reformer - All Levels",
  category: :reformer,
  duration_minutes: 55,
  default_capacity: 8,
  description: "Classic Reformer class suitable for all levels"
}
```

**Testing Strategy**:
- Test create action with valid attributes
- Test capacity validation (must be > 0)
- Test duration validation
- Test template creation
- Test multi-tenant isolation (class types belong to studio)

**Dependencies**:
- PHX-4 (Classes domain - ClassType resource)
- PHX-3 (Studios.Studio)

---

#### PHX-14: Initial Schedule Creation
**Source**: WLS-97 (Recurring Classes), WLS-101 Step 5

**User Story**:
As a studio owner
I want to create my initial weekly class schedule
So that clients can see and book my classes

**Use Cases**:
```gherkin
Scenario: [Happy Path] Owner creates recurring Monday morning Reformer class
  Given I completed Steps 1-4 of onboarding
  When I navigate to Step 5 "Class Schedule"
  And I select class type "Reformer - Intermediate"
  And I select instructor "Jane Doe"
  And I select day "Monday"
  And I select start time "9:00 AM"
  And I set recurrence "Weekly"
  And I set start date "2025-01-20"
  And I click "Add to Schedule"
  Then "Reformer - Intermediate" appears in Monday 9am slot
  And recurring schedule template is created
  And I can proceed to Step 6

Scenario: [Edge Case] Owner creates schedule without instructor assigned
  Given I am creating a class schedule
  When I leave "Instructor" field empty
  And I complete other required fields
  And I click "Add to Schedule"
  Then schedule is created with "Unassigned" instructor
  And I see warning "Remember to assign instructor before going live"

Scenario: [Error Case] Owner creates overlapping schedule
  Given I have "Reformer" on Monday 9:00-10:00
  When I try to add "Mat" on Monday 9:30-10:30 in same room
  And I click "Add to Schedule"
  Then I see error "Schedule conflicts with existing class"
  And schedule is not created
```

**Acceptance Criteria**:
1. Can create recurring class schedules
2. Select: class type, instructor, day/time, room, recurrence pattern
3. Schedule conflict detection (same room/time)
4. Multiple schedules can be added
5. Can preview generated sessions for next 4 weeks

**Phoenix/Ash Implementation**:

**Domain**: Classes

**Resources**:
- Classes.ClassSchedule
  - Action: `:create_recurring`
  - Attributes: class_type_id, instructor_id, room_id, day_of_week, start_time, duration_minutes, recurrence_pattern, start_date
  - Validation: No overlapping schedules in same room

**LiveView**:
- `PilatesOnPhxWeb.OnboardingLive.InitialSchedule`
- Calendar view of weekly schedule
- Form to add recurring classes
- Preview of generated sessions

**Ash Actions**:
```elixir
# lib/pilates_on_phx/classes/class_schedule.ex
create :create_recurring do
  accept [:class_type_id, :instructor_id, :room_id, :day_of_week, 
          :start_time, :duration_minutes, :recurrence_pattern, :start_date]
  
  argument :studio_id, :uuid, allow_nil?: false
  
  change relate_actor(:studio)
  
  validate present([:class_type_id, :day_of_week, :start_time, :start_date])
  validate one_of(:day_of_week, 0..6)
  validate one_of(:recurrence_pattern, [:weekly, :biweekly, :monthly])
  
  # Custom validation: no overlapping schedules in same room
  validate fn changeset, _context ->
    room_id = Ash.Changeset.get_attribute(changeset, :room_id)
    day = Ash.Changeset.get_attribute(changeset, :day_of_week)
    start_time = Ash.Changeset.get_attribute(changeset, :start_time)
    duration = Ash.Changeset.get_attribute(changeset, :duration_minutes)
    
    case check_schedule_conflict(room_id, day, start_time, duration) do
      :ok -> :ok
      {:error, msg} -> {:error, field: :start_time, message: msg}
    end
  end
end
```

**Oban Job** (Session Generation):
```elixir
# lib/pilates_on_phx/classes/workers/generate_class_sessions.ex
defmodule PilatesOnPhx.Classes.Workers.GenerateClassSessions do
  use Oban.Worker, queue: :default
  
  def perform(%{args: %{"schedule_id" => schedule_id, "weeks_ahead" => weeks}}) do
    schedule = PilatesOnPhx.Classes.get_schedule!(schedule_id)
    # Generate ClassSession instances for next N weeks
    PilatesOnPhx.Classes.generate_sessions_from_schedule(schedule, weeks)
  end
end
```

**Testing Strategy**:
- Test recurring schedule creation
- Test schedule conflict detection
- Test different recurrence patterns (weekly, biweekly)
- Test session generation (unit test for algorithm)
- Integration test: schedule creation triggers Oban job

**Dependencies**:
- PHX-13 (ClassType created)
- PHX-12 (Instructor available, or allow unassigned)
- PHX-3 (Room resource)

---

#### PHX-15: Onboarding Completion and Launch
**Source**: WLS-101 Step 6

**User Story**:
As a studio owner
I want to review my onboarding setup and launch my studio
So that clients can start booking classes

**Use Cases**:
```gherkin
Scenario: [Happy Path] Owner completes onboarding and launches studio
  Given I completed Steps 1-5 of onboarding
  When I navigate to Step 6 "Review & Launch"
  Then I see summary of my setup:
    - Studio info
    - Business model
    - Staff members
    - Class types
    - Weekly schedule
  When I review all details
  And I click "Launch My Studio"
  Then my studio status changes to "Active"
  And I see "Congratulations" success message
  And I am redirected to studio dashboard
  And clients can now see and book my classes

Scenario: [Edge Case] Owner launches with incomplete setup
  Given I completed Steps 1-3 but skipped 4-5
  When I navigate to Step 6 "Review & Launch"
  Then I see warnings for incomplete steps:
    - "No class types defined"
    - "No schedule created"
  And "Launch" button is disabled
  And I see "Complete required steps to launch"

Scenario: [Error Case] Owner tries to launch with no staff
  Given I completed all steps but have no staff
  When I click "Launch My Studio"
  Then I see error "You must have at least one instructor to launch"
  And studio remains in "Setup" status
```

**Acceptance Criteria**:
1. Summary view shows all onboarding data
2. Can edit any section before launching
3. Validation ensures minimum requirements met
4. Launch action changes studio status to "Active"
5. Welcome email sent with next steps

**Phoenix/Ash Implementation**:

**Domain**: Studios

**Resources**:
- Studios.Studio
  - Action: `:complete_onboarding`
  - Validation: Ensure minimum requirements (class types, schedule)
  - Attribute: `status` (enum: :setup, :active, :suspended)

**LiveView**:
- `PilatesOnPhxWeb.OnboardingLive.ReviewAndLaunch`
- Summary cards for each onboarding step
- Edit links to return to previous steps
- Launch button with confirmation modal

**Ash Actions**:
```elixir
# lib/pilates_on_phx/studios/studio.ex
update :complete_onboarding do
  change set_attribute(:status, :active)
  change set_attribute(:onboarding_completed_at, &DateTime.utc_now/0)
  
  validate fn changeset, _context ->
    studio = Ash.Changeset.data(changeset)
    
    cond do
      !has_class_types?(studio) ->
        {:error, field: :base, message: "Must define at least one class type"}
      
      !has_schedule?(studio) ->
        {:error, field: :base, message: "Must create at least one class schedule"}
      
      !has_instructor?(studio) ->
        {:error, field: :base, message: "Must have at least one instructor"}
      
      true ->
        :ok
    end
  end
  
  # Send welcome email
  change after_action(&send_welcome_email/2)
end
```

**Testing Strategy**:
- Test launch with complete setup (success)
- Test launch with incomplete setup (validation errors)
- Test status change to :active
- Test welcome email sent (Oban job)
- Integration test: full onboarding flow end-to-end

**Dependencies**:
- All previous onboarding steps (PHX-10 through PHX-14)
- Oban for email sending

---

### Epic PHX-16: Class Scheduling & Recurring Classes

**Parent**: None
**Priority**: Critical
**Estimated Stories**: 5
**Business Value**: Core scheduling functionality enables studio operations

**Description**: Enable studio owners and instructors to create, manage, and automate recurring class schedules with session generation.

**User Stories**:
- PHX-17: Create Single Class Session
- PHX-18: Create Recurring Class Schedule Template
- PHX-19: Generate Class Sessions from Schedule (Oban)
- PHX-20: Edit/Cancel Future Class Sessions
- PHX-21: Instructor Assignment and Substitution

---

### Epic PHX-22: Booking Workflow & Package Management

**Parent**: None
**Priority**: Critical
**Estimated Stories**: 8
**Business Value**: THE CORE REVENUE-GENERATING WORKFLOW

**Description**: Complete booking workflow from package purchase to class reservation to attendance check-in.

**User Stories**:
- PHX-23: Client Registration and Profile
- PHX-24: Browse Available Class Sessions
- PHX-25: Purchase Class Package
- PHX-26: Book Class with Credit Redemption
- PHX-27: Waitlist Entry and Auto-Promotion
- PHX-28: Cancel Booking with Refund Logic
- PHX-29: Package Expiration and Renewal
- PHX-30: Admin Dashboard - Booking Overview

---

## Sprint 3: Automation & Advanced Features

**Goal**: Add background job automation, attendance tracking, and communications.

**Duration**: 3 weeks

**Success Criteria**:
- Recurring class sessions generated automatically
- Attendance check-in working
- Email and SMS reminders sent
- Waitlist auto-promotion functional
- Scheduled reports delivered

### Epics for Sprint 3

---

### Epic PHX-31: Attendance & Check-In System

**Parent**: None
**Priority**: High
**Estimated Stories**: 4
**Business Value**: Track client attendance and enforce no-show policies

**User Stories**:
- PHX-32: Client Check-In at Front Desk
- PHX-33: Instructor Mobile Check-In
- PHX-34: No-Show Detection and Credit Penalty
- PHX-35: Attendance History and Reports

---

### Epic PHX-36: Automation & Background Jobs

**Parent**: None
**Priority**: High
**Estimated Stories**: 5
**Business Value**: Reduce manual work and improve client experience

**User Stories**:
- PHX-37: Automated Class Session Generation (Nightly Oban)
- PHX-38: Email Reminders 24h Before Class
- PHX-39: SMS Reminders (Twilio Integration)
- PHX-40: Scheduled Financial Reports
- PHX-41: Package Expiration Notifications

---

### Epic PHX-42: Client & Instructor Dashboards

**Parent**: None
**Priority**: Medium
**Estimated Stories**: 4
**Business Value**: Improve UX with personalized views

**User Stories**:
- PHX-43: Client Dashboard with Upcoming Bookings
- PHX-44: Client Booking History and Credits
- PHX-45: Instructor Dashboard with Schedule
- PHX-46: Instructor Class Roster View

---

## Sprint 4: Integrations & Polish

**Goal**: Add payment processing, advanced reporting, and mobile PWA features.

**Duration**: 3 weeks

**Success Criteria**:
- Stripe payment integration working
- Financial and attendance reports generated
- Mobile PWA installable
- Analytics dashboards functional
- Production-ready quality

### Epics for Sprint 4

---

### Epic PHX-47: Payments & Stripe Integration

**Parent**: None
**Priority**: High
**Estimated Stories**: 6
**Business Value**: Enable real payment processing

**User Stories**:
- PHX-48: Stripe Connect Setup for Studio
- PHX-49: Credit Card Payment for Packages
- PHX-50: Recurring Membership Billing
- PHX-51: Refund Processing
- PHX-52: Invoice Generation
- PHX-53: Payment History and Reporting

---

### Epic PHX-54: Reporting & Analytics

**Parent**: None
**Priority**: Medium
**Estimated Stories**: 5
**Business Value**: Business intelligence for studio owners

**User Stories**:
- PHX-55: Revenue Report by Date Range
- PHX-56: Attendance Report by Class Type
- PHX-57: Client Retention Metrics
- PHX-58: Instructor Performance Dashboard
- PHX-59: Custom Report Builder

---

### Epic PHX-60: Mobile PWA & Advanced UX

**Parent**: None
**Priority**: Medium
**Estimated Stories**: 4
**Business Value**: Mobile-first experience for clients

**User Stories**:
- PHX-61: PWA Installation and Offline Support
- PHX-62: Push Notifications for Bookings
- PHX-63: Biometric Authentication (Touch ID/Face ID)
- PHX-64: Mobile-Optimized Class Booking UI

---

## Summary Statistics

### Sprint 1 (Foundation)
- **Issues**: 8 (PHX-1 through PHX-8, with PHX-5+6 merged)
- **Duration**: 2 weeks
- **Focus**: Domain architecture, core resources, multi-tenant policies

### Sprint 2 (Core Workflows)
- **Epics**: 3
- **Stories**: 19+ (PHX-9 through PHX-30)
- **Duration**: 3 weeks
- **Focus**: Onboarding, scheduling, booking workflow

### Sprint 3 (Automation)
- **Epics**: 3
- **Stories**: 13+ (PHX-31 through PHX-46)
- **Duration**: 3 weeks
- **Focus**: Attendance, automation, dashboards

### Sprint 4 (Integrations)
- **Epics**: 3
- **Stories**: 15+ (PHX-47 through PHX-64)
- **Duration**: 3 weeks
- **Focus**: Payments, reporting, mobile PWA

### Total
- **Sprints**: 4 (11 weeks total)
- **Epics**: 9+
- **Stories**: 55+
- **Domains**: 4 (Accounts, Studios, Classes, Bookings)

