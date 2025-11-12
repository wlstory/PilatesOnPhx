# Sprint 2 - Complete Linear Issue Specifications

**Ready to Create in Linear**

**Project**: Sprint 2 - Core User Workflows (ID: 9f2b68bd-c266-4da0-b220-bd05196f3124)
**Team**: AltBuild-PHX (ID: 6e4b0bca-146e-4a33-8c4a-314f6f7d5834)

---

## EPIC PHX-12: Booking Workflow & Package Management

**Type**: Epic
**Priority**: 1 (Urgent)
**Labels**: epic, booking, core-workflow, sprint-2, critical
**Parent**: None
**Project**: Sprint 2 - Core User Workflows

### Title
Booking Workflow & Package Management

### Description

Implement the complete booking workflow - THE CORE REVENUE WORKFLOW for Pilates studios. This epic covers client registration, package purchases with Stripe integration, real-time class booking with credit management, waitlist automation, and attendance tracking.

**Original Source**: WLS-67 (Cancel Booking), WLS-71 (Check-In), WLS-98 (Package Conversion), WLS-60 (Recurring Booking)

#### Problem Statement

The booking workflow is the primary revenue driver for Pilates studios. Clients must be able to:
1. Purchase credit packages
2. Book classes using those credits
3. Join waitlists when full
4. Check in for classes
5. Track attendance history

All operations must be atomic (credit deduction + booking creation) to prevent race conditions and overselling.

#### Scope

**Client Management**:
- Client registration and profile creation
- Emergency contact information
- Preferences and notes
- Booking history

**Package System**:
- Package types (10-class, 20-class, monthly unlimited)
- Stripe payment integration
- Credit allocation and tracking
- Package expiration logic
- Package conversion requests

**Booking Flow**:
- Browse available classes with real-time capacity
- Book class with atomic credit deduction
- Capacity validation
- Confirmation notifications
- Booking history

**Waitlist Management**:
- Auto-join waitlist when class full
- Position tracking
- Auto-promotion on cancellation
- 24-hour confirmation window
- Waitlist notifications

**Check-In & Attendance**:
- Batch check-in interface for staff
- Mark attendance
- Track no-shows
- Attendance reports

### Use Cases

```gherkin
Scenario: [Happy Path] Complete booking workflow
  Given a new client registers on the platform
  When they purchase a "10-Class Package" for $150
  And they browse available classes
  And they book "Reformer Pilates" on Tuesday at 10am
  Then their package is created with 10 credits
  And 1 credit is atomically deducted
  And booking is confirmed
  And they receive confirmation email
  And class capacity decreases by 1

Scenario: [Happy Path] Waitlist workflow
  Given a class with 0 available spots
  When a client tries to book the class
  Then they are automatically added to waitlist
  And no credits are deducted
  And they receive waitlist confirmation showing position #3
  And when spot opens, first waitlisted client is notified

Scenario: [Edge Case] Concurrent booking race condition
  Given a class with 1 available spot
  When 2 clients try to book simultaneously
  Then only 1 booking succeeds (database transaction)
  And the other client is added to waitlist
  And both clients receive appropriate notifications

Scenario: [Error Case] Insufficient credits
  Given a client with 0 credits
  When they try to book a class
  Then booking is rejected
  And error shows "Insufficient credits. Purchase a package to continue."
  And they are redirected to package purchase page
```

### Children Stories
- PHX-25: Client Registration & Profile
- PHX-26: Package Purchase with Stripe
- PHX-27: Browse Available Classes
- PHX-28: Book Class with Credits
- PHX-29: Join Waitlist When Full
- PHX-30: Cancel Booking
- PHX-31: Staff Batch Check-In
- PHX-32: Package Conversion Request
- PHX-33: Attendance Tracking

### Dependencies
- PHX-2: Accounts Domain (User)
- PHX-3: Studios Domain (Studio)
- PHX-4: Classes Domain (ClassSession)
- PHX-9: Bookings Domain resources defined
- PHX-11: Class Scheduling (for browsing classes)

### Success Criteria
- 95%+ booking success rate (no race conditions)
- < 2 seconds for booking confirmation
- Zero credit leakage (atomic operations)
- Waitlist promotion < 5 minutes
- Stripe payment success rate > 98%

---

## PHX-13: Studio Basic Information Capture

**Type**: Story
**Priority**: 1 (Urgent)
**Labels**: onboarding, studios-domain, sprint-2
**Parent**: PHX-10
**Project**: Sprint 2 - Core User Workflows

### Title
Studio Basic Information Capture (Onboarding Step 1)

### User Story
As a Studio Owner, I want to enter basic studio information during onboarding, so that my studio profile is created with correct contact details and branding.

### Description

First step in the onboarding wizard where studio owners enter essential business information including name, location, contact details, and branding elements.

**Original Source**: WLS-102 (NextJS)

**Context**: This is the foundation of the studio profile. All subsequent onboarding steps depend on this basic information being captured and validated.

### Use Cases

```gherkin
Scenario: [Happy Path] Owner completes basic studio info
  Given a new owner starts the onboarding wizard
  When they enter studio name "Phoenix Pilates Studio"
  And they enter address "123 Main St, Phoenix, AZ 85001"
  And they enter phone "(602) 555-1234"
  And they enter email "info@phoenixpilates.com"
  And they upload a logo image (PNG, 500KB)
  And they select primary color "#4F7CAC"
  And they click "Save & Continue"
  Then studio record is created in database
  And logo is uploaded to storage
  And onboarding progress advances to step 2
  And success message shows "Studio information saved"

Scenario: [Edge Case] Owner saves and exits mid-form
  Given owner is filling out basic studio info
  When they have entered name and address only
  And they click "Save & Exit"
  Then partial data is saved to session
  And they can resume onboarding later
  And form pre-fills with saved data

Scenario: [Error Case] Invalid phone format
  Given owner enters phone "123456"
  When they click "Save & Continue"
  Then validation error shows "Phone must be format: (XXX) XXX-XXXX"
  And form does not advance
  And entered data is preserved
```

### Acceptance Criteria

1. Form fields: studio name (required), address, city, state, ZIP, phone, email, website
2. Logo upload with validation: PNG/JPG/SVG, max 2MB
3. Color picker for primary brand color
4. Phone format validation: (XXX) XXX-XXXX
5. Email format validation
6. URL validation for website
7. Progress indicator shows "Step 1 of 6"
8. "Save & Exit" button saves to session
9. "Next" button validates and advances
10. Inline error messages for validation failures

### Technical Implementation

**Domain**: Studios

**Ash Resource Action**:
```elixir
# lib/pilates_on_phx/studios/studio.ex
create :onboarding_basic_info do
  accept [:name, :address, :city, :state, :zip, :phone, :email, :website, :primary_color]

  validate present(:name)
  validate match(:phone, ~r/^\(\d{3}\) \d{3}-\d{4}$/)
  validate match(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/)

  change upload_logo()  # Custom change for file upload
  change set_defaults()
end
```

**LiveView**: `PilatesOnPhxWeb.Onboarding.BasicInfoLive`
**File Upload**: Phoenix.LiveView.UploadConfig with 2MB limit

**References**:
- `/Users/wlstory/src/PilatesOnPhx/lib/pilates_on_phx/studios/studio.ex`
- `/Users/wlstory/src/PilatesOnPhx/AGENTS.md` - LiveView patterns (lines 450-550)

### Testing Strategy

- LiveViewTest for form interactions
- Test validation rules (phone, email, URL)
- Test file upload (mock upload)
- Test save-and-exit functionality
- Test form pre-population on resume
- 85%+ coverage

### Dependencies

- PHX-3: Studios Domain (Studio resource)
- PHX-10: Epic parent

### Definition of Done

- [ ] All acceptance criteria met
- [ ] Form validation working
- [ ] File upload functional
- [ ] Tests passing (85%+ coverage)
- [ ] LiveView component renders correctly
- [ ] Onboarding progress tracking works
- [ ] Code reviewed
- [ ] Deployed to staging

---

## PHX-14: Owner Account Initial Setup

**Type**: Story
**Priority**: 1 (Urgent)
**Labels**: onboarding, accounts-domain, authentication, sprint-2
**Parent**: PHX-10
**Project**: Sprint 2 - Core User Workflows

### Title
Owner Account Initial Setup (Onboarding Step 2)

### User Story
As a new studio owner, I want to create my account with secure authentication, so that I can access the platform and manage my studio.

### Description

Implements secure user registration with AshAuthentication, supporting email/password and OAuth providers. Auto-creates Organization and Studio records via database trigger when owner account is created.

**Original Source**: WLS-108, WLS-135 (NextJS)

**Context**: This is the authentication foundation. The database trigger ensures every owner automatically gets an Organization and Studio created, establishing the multi-tenant structure.

### Use Cases

```gherkin
Scenario: [Happy Path] Owner signs up with email/password
  Given a new user visits the signup page
  When they enter email "owner@studio.com"
  And they enter a strong password "SecurePass123!"
  And they confirm the password
  And they accept Terms of Service
  Then a User record is created with role "owner"
  And an Organization record is auto-created
  And a Studio record is auto-created linked to the organization
  And onboarding_progress record is created at step 1
  And verification email is sent
  And they are redirected to onboarding step 1

Scenario: [Happy Path] Owner signs up with Google OAuth
  Given a new user clicks "Sign up with Google"
  When they complete Google OAuth flow
  Then User record is created from Google profile
  And Organization and Studio auto-created via database trigger
  And they are redirected to onboarding step 1

Scenario: [Error Case] Duplicate email address
  Given a user with email "owner@studio.com" exists
  When a new user tries to sign up with same email
  Then signup fails with error "Email already registered"
  And they are offered "Forgot password?" link
```

### Acceptance Criteria

1. Email/password signup using AshAuthentication
2. OAuth providers: Google, Apple (optional)
3. Password requirements: min 8 chars, 1 uppercase, 1 lowercase, 1 number
4. Email verification required
5. Database trigger auto-creates Organization + Studio + onboarding_progress
6. User assigned "owner" role
7. Terms of Service acceptance required
8. Error handling for duplicate emails
9. Redirect to onboarding wizard after successful signup
10. Can resume onboarding if interrupted

### Technical Implementation

**Domain**: Accounts

**Ash Resource with AshAuthentication**:
```elixir
# lib/pilates_on_phx/accounts/user.ex
authentication do
  strategies do
    password :password do
      identity_field :email
      register_action_accept [:email, :role]
    end

    oauth2 :google do
      client_id &get_config/2
      client_secret &get_config/2
    end
  end

  tokens do
    enabled? true
    token_resource PilatesOnPhx.Accounts.Token
  end
end
```

**Database Trigger** (PostgreSQL):
```sql
CREATE OR REPLACE FUNCTION handle_new_owner_signup()
RETURNS TRIGGER AS $$
DECLARE
  new_org_id UUID;
  new_studio_id BIGINT;
BEGIN
  IF NEW.role = 'owner' THEN
    INSERT INTO organizations (name, created_at, updated_at)
    VALUES ('New Organization', NOW(), NOW())
    RETURNING id INTO new_org_id;

    UPDATE users SET organization_id = new_org_id WHERE id = NEW.id;

    INSERT INTO studios (name, organization_id, owner_id, created_at, updated_at)
    VALUES ('My Studio', new_org_id, NEW.id, NOW(), NOW())
    RETURNING id INTO new_studio_id;

    INSERT INTO studio_onboarding_progress (studio_id, current_step, created_at, updated_at)
    VALUES (new_studio_id, 1, NOW(), NOW());
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

**LiveView**: `PilatesOnPhxWeb.Auth.RegisterLive`

**References**:
- `/Users/wlstory/src/PilatesOnPhx/lib/pilates_on_phx/accounts/user.ex`
- `/Users/wlstory/src/PilatesOnPhx/AGENTS.md` - AshAuthentication patterns (lines 800-900)

### Testing Strategy

- Test email/password registration
- Test OAuth registration (mock providers)
- Test password validation rules
- Test duplicate email handling
- Test database trigger (org/studio auto-creation)
- Test email verification flow
- Integration test for complete signup → onboarding
- 85%+ coverage

### Dependencies

- PHX-2: Accounts Domain (User, Organization, Token)
- PHX-3: Studios Domain (Studio, StudioOnboardingProgress)
- AshAuthentication package

### Definition of Done

- [ ] Email/password auth working
- [ ] OAuth providers integrated (Google)
- [ ] Database trigger functional
- [ ] Email verification implemented
- [ ] Tests passing
- [ ] Security audit complete
- [ ] Code reviewed
- [ ] Deployed to staging

---

## PHX-15: Business Model Selection

**Type**: Story
**Priority**: 1 (Urgent)
**Labels**: onboarding, studios-domain, business-model, sprint-2
**Parent**: PHX-10
**Project**: Sprint 2 - Core User Workflows

### Title
Business Model Selection (Onboarding Step 3)

### User Story
As a studio owner, I want to select my business model (Standard vs Contract Labor), so that the platform configures appropriate features and reporting for my revenue model.

### Description

Critical decision point in onboarding where the owner selects between two business models. This selection determines feature flags, reporting templates, and the entire revenue tracking approach.

**Original Source**: WLS-101 (Business Model Section)

**Context**: This is a foundational business decision that cannot easily be changed later. Standard studios track class bookings revenue, while Contract Labor studios track room rental revenue.

### Use Cases

```gherkin
Scenario: [Happy Path] Owner selects Standard Studio model
  Given owner is on business model selection step
  When they select "Standard Studio with Employees"
  And they read the implications explanation
  And they click "Continue"
  Then studio.business_model is set to "standard"
  And feature flags are configured for employee model
  And reporting templates are set to class revenue tracking
  And onboarding advances to step 4

Scenario: [Happy Path] Owner selects Contract Labor model
  Given owner is on business model selection step
  When they select "Contract Labor Renting Space"
  And they read the implications explanation
  And they click "Continue"
  Then studio.business_model is set to "contract_labor"
  And feature flags enable room rental fees
  And reporting templates are set to rental revenue tracking
  And onboarding advances to step 4

Scenario: [Error Case] Owner tries to skip without selection
  Given owner is on business model selection step
  When they click "Continue" without making a selection
  Then error shows "Please select a business model to continue"
  And form does not advance
```

### Acceptance Criteria

1. Two radio options: "Standard Studio" and "Contract Labor"
2. Each option has detailed explanation of implications
3. Standard Studio explanation: W-2 employees, class booking revenue, package sales
4. Contract Labor explanation: 1099 contractors, room rental revenue, instructor payments
5. Cannot proceed without selection
6. Selection saves to studio.business_model field
7. Feature flags configured based on selection
8. Reporting templates configured based on selection
9. Progress indicator shows "Step 3 of 6"
10. Can change selection later in settings (with warning)

### Technical Implementation

**Domain**: Studios

**Ash Resource Action**:
```elixir
# lib/pilates_on_phx/studios/studio.ex
update :set_business_model do
  accept [:business_model]

  validate one_of(:business_model, [:standard, :contract_labor])

  change configure_feature_flags()
  change set_reporting_templates()
  change update_onboarding_progress(step: 3)
end
```

**LiveView**: `PilatesOnPhxWeb.Onboarding.BusinessModelLive`

**References**:
- `/Users/wlstory/src/PilatesOnPhx/lib/pilates_on_phx/studios/studio.ex`
- `/Users/wlstory/src/PilatesOnPhx/docs/product-management/SPRINT_2_ISSUES_TO_CREATE.md` (lines 673-846)

### Testing Strategy

- Test standard model selection and feature flags
- Test contract labor model selection and flags
- Test validation (cannot skip)
- Test LiveView form submission
- Test reporting template configuration
- 85%+ coverage

### Dependencies

- PHX-3: Studios Domain (Studio resource)
- PHX-13: Basic studio info must be complete

### Definition of Done

- [ ] Radio selection working
- [ ] Feature flags configured correctly
- [ ] Reporting templates set
- [ ] Validation prevents skipping
- [ ] Tests passing
- [ ] Can change later in settings
- [ ] Code reviewed
- [ ] Deployed

---

## PHX-16: Studio Configuration Settings

**Type**: Story
**Priority**: 1 (Urgent)
**Labels**: onboarding, studios-domain, configuration, sprint-2
**Parent**: PHX-10
**Project**: Sprint 2 - Core User Workflows

### Title
Studio Configuration Settings (Onboarding Step 4)

### User Story
As a studio owner, I want to configure operational settings like timezone, booking policies, and cancellation rules, so that the platform operates according to my business policies.

### Description

Configure essential operational settings that govern how the studio operates, including timezone, booking windows, cancellation policies, and business hours.

**Context**: These settings directly impact client experience and business operations. Must be configured before classes can be created.

### Use Cases

```gherkin
Scenario: [Happy Path] Owner configures studio settings
  Given owner is on studio configuration step
  When they select timezone "America/Phoenix"
  And they set booking window to "24 hours in advance"
  And they set cancellation policy "Full refund if cancelled 12+ hours before"
  And they set business hours "Mon-Fri 6am-8pm, Sat-Sun 8am-5pm"
  And they click "Save & Continue"
  Then settings are saved to studio record
  And onboarding advances to step 5
  And success message shows "Configuration saved"

Scenario: [Edge Case] Owner uses default settings
  Given owner is on studio configuration step
  When they click "Use Recommended Defaults"
  Then timezone defaults to browser timezone
  And booking window defaults to 2 hours
  And cancellation policy defaults to 24-hour policy
  And settings are saved

Scenario: [Error Case] Conflicting business hours
  Given owner sets opening time "10am"
  And owner sets closing time "8am"
  When they try to save
  Then error shows "Closing time must be after opening time"
```

### Acceptance Criteria

1. Timezone selector with all valid timezones
2. Booking window: dropdown (1hr, 2hr, 4hr, 12hr, 24hr, 48hr)
3. Cancellation policy configuration with refund % and time threshold
4. Business hours: per-day time pickers (Monday-Sunday)
5. Toggle for "Closed" days
6. "Use Recommended Defaults" button
7. Validation: closing time after opening time
8. Preview of how policies affect client booking experience
9. Progress indicator shows "Step 4 of 6"
10. Settings saved to studio.settings JSONB field

### Technical Implementation

**Domain**: Studios

**Ash Resource**:
```elixir
# lib/pilates_on_phx/studios/studio.ex
attribute :settings, :map do
  default %{
    timezone: "America/Los_Angeles",
    booking_window_hours: 2,
    cancellation_policy: %{
      refund_percent: 100,
      hours_before: 24
    },
    business_hours: %{
      monday: %{open: "06:00", close: "20:00", closed: false},
      # ... other days
    }
  }
end

update :configure_settings do
  accept [:settings]
  validate validate_business_hours()
  validate validate_cancellation_policy()
end
```

**LiveView**: `PilatesOnPhxWeb.Onboarding.ConfigurationLive`

**References**:
- `/Users/wlstory/src/PilatesOnPhx/lib/pilates_on_phx/studios/studio.ex`

### Testing Strategy

- Test settings save and retrieval
- Test timezone handling
- Test business hours validation
- Test cancellation policy configuration
- Test default settings
- 85%+ coverage

### Dependencies

- PHX-3: Studios Domain
- PHX-15: Business model must be selected

### Definition of Done

- [ ] All configuration options working
- [ ] Validation rules enforced
- [ ] Default settings functional
- [ ] Tests passing
- [ ] Settings preview accurate
- [ ] Code reviewed
- [ ] Deployed

---

## PHX-17: Class Types Setup

**Type**: Story
**Priority**: 1 (Urgent)
**Labels**: onboarding, classes-domain, sprint-2
**Parent**: PHX-10
**Project**: Sprint 2 - Core User Workflows

### Title
Class Types Setup (Onboarding Step 5)

### User Story
As a studio owner, I want to define class types offered at my studio (e.g., Reformer Pilates, Mat Pilates, HIIT), so that I can schedule classes and clients can book them.

### Description

Define the catalog of class types offered. Each class type has a name, description, duration, capacity, and optional equipment requirements.

**Context**: Class types are the building blocks of the scheduling system. They define what services the studio offers.

### Use Cases

```gherkin
Scenario: [Happy Path] Owner creates multiple class types
  Given owner is on class types setup step
  When they click "Add Class Type"
  And they enter name "Reformer Pilates - Beginner"
  And they enter description "Introductory reformer class..."
  And they set duration to "55 minutes"
  And they set max capacity to "8 clients"
  And they select equipment "Reformer x8"
  And they click "Save Class Type"
  Then class type is created
  And they can add another class type
  And list shows "Reformer Pilates - Beginner"

Scenario: [Edge Case] Owner uses default class types
  Given owner is on class types setup step
  When they click "Use Standard Pilates Class Types"
  Then default types are created: "Reformer - All Levels", "Mat Pilates", "Stretch & Align"
  And owner can edit or delete defaults
  And onboarding advances to step 6

Scenario: [Error Case] Duplicate class type name
  Given class type "Reformer Pilates" exists
  When owner tries to create another "Reformer Pilates"
  Then error shows "Class type name must be unique"
```

### Acceptance Criteria

1. Form to add class type: name, description, duration, capacity
2. Equipment selector (from inventory if available)
3. Color picker for calendar display
4. "Add Another" button for multiple types
5. "Use Standard Pilates Class Types" for defaults
6. List view of created class types with edit/delete
7. Validation: unique names within studio
8. Validation: duration 15-180 minutes
9. Validation: capacity 1-50 clients
10. Progress indicator shows "Step 5 of 6"

### Technical Implementation

**Domain**: Classes

**Ash Resource**:
```elixir
# lib/pilates_on_phx/classes/class_type.ex
attributes do
  attribute :name, :string
  attribute :description, :string
  attribute :duration_minutes, :integer
  attribute :max_capacity, :integer
  attribute :color, :string
  attribute :equipment_requirements, {:array, :string}
end

relationships do
  belongs_to :studio, PilatesOnPhx.Studios.Studio
end

validations do
  validate present([:name, :duration_minutes, :max_capacity])
  validate number(:duration_minutes, min: 15, max: 180)
  validate number(:max_capacity, min: 1, max: 50)
end
```

**LiveView**: `PilatesOnPhxWeb.Onboarding.ClassTypesLive`

**References**:
- `/Users/wlstory/src/PilatesOnPhx/lib/pilates_on_phx/classes/class_type.ex`

### Testing Strategy

- Test class type creation
- Test validations (unique name, duration, capacity)
- Test default class types
- Test edit/delete functionality
- 85%+ coverage

### Dependencies

- PHX-4: Classes Domain (ClassType resource)
- PHX-16: Studio settings configured

### Definition of Done

- [ ] Class type CRUD working
- [ ] Validations enforced
- [ ] Default types functional
- [ ] Tests passing
- [ ] Code reviewed
- [ ] Deployed

---

## PHX-18: Rooms & Facilities Management

**Type**: Story
**Priority**: 1 (Urgent)
**Labels**: onboarding, studios-domain, facilities, sprint-2
**Parent**: PHX-10
**Project**: Sprint 2 - Core User Workflows

### Title
Rooms & Facilities Management (Onboarding Step 6)

### User Story
As a studio owner, I want to define rooms and facilities in my studio, so that I can assign classes to specific locations and track room availability.

### Description

Define the physical spaces where classes are held. Rooms have capacity limits and equipment assignments.

**Context**: For contract labor model, rooms are billable units. For standard model, rooms are scheduling resources.

### Use Cases

```gherkin
Scenario: [Happy Path] Owner creates studio rooms
  Given owner is on rooms setup step
  When they click "Add Room"
  And they enter name "Studio A - Main Room"
  And they set capacity to "12 clients"
  And they assign equipment "8 Reformers, 2 Cadillacs"
  And they upload room photo
  And they click "Save Room"
  Then room is created
  And they can add another room
  And list shows "Studio A - Main Room"

Scenario: [Edge Case] Single room studio
  Given owner has only one room
  When they enter "Main Studio Room"
  And they click "Save & Finish Onboarding"
  Then single room is created
  And onboarding is marked complete
  And they are redirected to dashboard

Scenario: [Error Case] Room capacity exceeds building capacity
  Given studio max capacity is 20 clients
  When owner creates room with capacity 25
  Then error shows "Room capacity cannot exceed studio capacity"
```

### Acceptance Criteria

1. Form to add room: name, capacity, description
2. Equipment assignment (from inventory)
3. Photo upload for room
4. "Add Another Room" button
5. "Skip - I have one main room" option
6. List view with edit/delete
7. Validation: capacity must be positive integer
8. Room assigned default name if skipped
9. Progress indicator shows "Step 6 of 6"
10. "Finish Onboarding" button redirects to dashboard

### Technical Implementation

**Domain**: Studios

**Ash Resource**:
```elixir
# lib/pilates_on_phx/studios/room.ex
attributes do
  attribute :name, :string
  attribute :capacity, :integer
  attribute :description, :string
  attribute :photo_url, :string
  attribute :equipment, {:array, :string}
end

relationships do
  belongs_to :studio, PilatesOnPhx.Studios.Studio
end

validations do
  validate present([:name, :capacity])
  validate number(:capacity, min: 1)
end
```

**LiveView**: `PilatesOnPhxWeb.Onboarding.RoomsLive`

**References**:
- `/Users/wlstory/src/PilatesOnPhx/lib/pilates_on_phx/studios/room.ex`

### Testing Strategy

- Test room creation
- Test validations
- Test skip option (default room creation)
- Test onboarding completion
- 85%+ coverage

### Dependencies

- PHX-3: Studios Domain (Room resource)
- PHX-17: Class types configured

### Definition of Done

- [ ] Room CRUD working
- [ ] Validations enforced
- [ ] Skip option functional
- [ ] Onboarding completion flow working
- [ ] Tests passing
- [ ] Code reviewed
- [ ] Deployed

---

## PHX-19: Equipment Inventory (Optional)

**Type**: Story
**Priority**: 1 (Urgent)
**Labels**: onboarding, studios-domain, inventory, optional, sprint-2
**Parent**: PHX-10
**Project**: Sprint 2 - Core User Workflows

### Title
Equipment Inventory Management (Optional Onboarding Step)

### User Story
As a studio owner, I want to track equipment inventory (reformers, mats, props), so that I can assign equipment to rooms and ensure adequate resources for classes.

### Description

Optional step to catalog studio equipment. Particularly useful for studios with multiple rooms and equipment-intensive classes.

**Context**: Equipment tracking helps prevent overbooking and ensures proper resource allocation. Can be skipped and added later.

### Use Cases

```gherkin
Scenario: [Happy Path] Owner catalogs equipment
  Given owner is on equipment inventory step
  When they click "Add Equipment"
  And they select type "Reformer"
  And they enter quantity "8"
  And they enter notes "Balanced Body Reformers, purchased 2023"
  And they click "Save"
  Then equipment is added to inventory
  And quantity is available for room assignment

Scenario: [Edge Case] Owner skips equipment tracking
  Given owner is on equipment inventory step
  When they click "Skip - Add Later"
  Then onboarding continues to next step
  And equipment inventory remains empty
  And owner can add equipment later in settings

Scenario: [Error Case] Negative quantity
  Given owner enters quantity "-5"
  When they try to save
  Then error shows "Quantity must be positive"
```

### Acceptance Criteria

1. Form to add equipment: type, quantity, notes
2. Equipment types: Reformer, Cadillac, Chair, Tower, Mat, Props
3. "Add Another" button
4. "Skip - Add Later" option (prominent)
5. List view with edit/delete
6. Validation: positive quantities
7. Equipment available for assignment in room setup
8. Can be accessed later in Settings
9. Progress indicator shows "Step 6b of 6" (optional)
10. Does not block onboarding completion

### Technical Implementation

**Domain**: Studios

**Ash Resource**:
```elixir
# lib/pilates_on_phx/studios/equipment.ex
attributes do
  attribute :equipment_type, :atom # :reformer, :cadillac, :chair, etc.
  attribute :quantity, :integer
  attribute :notes, :string
  attribute :purchase_date, :date
end

relationships do
  belongs_to :studio, PilatesOnPhx.Studios.Studio
end

validations do
  validate present([:equipment_type, :quantity])
  validate number(:quantity, min: 1)
end
```

**LiveView**: `PilatesOnPhxWeb.Onboarding.EquipmentLive`

**References**:
- `/Users/wlstory/src/PilatesOnPhx/lib/pilates_on_phx/studios/equipment.ex`

### Testing Strategy

- Test equipment creation
- Test skip functionality
- Test validations
- Test equipment type enum
- 85%+ coverage

### Dependencies

- PHX-3: Studios Domain (Equipment resource)
- PHX-18: Rooms setup (equipment can be assigned)

### Definition of Done

- [ ] Equipment CRUD working
- [ ] Skip option functional
- [ ] Validations enforced
- [ ] Equipment types enum working
- [ ] Tests passing
- [ ] Can be accessed post-onboarding
- [ ] Code reviewed
- [ ] Deployed

---

## PHX-20: Create Single Class Session

**Type**: Story
**Priority**: 2 (High)
**Labels**: scheduling, classes-domain, sprint-2
**Parent**: PHX-11
**Project**: Sprint 2 - Core User Workflows

### Title
Create Single Class Session

### User Story
As a studio owner or instructor, I want to create a single class session at a specific date and time, so that clients can book it.

### Description

Basic class scheduling functionality - create a one-off class session. Foundation for the scheduling system.

**Context**: Single sessions are used for special events, makeup classes, or studios that don't use recurring schedules.

### Use Cases

```gherkin
Scenario: [Happy Path] Owner creates single class
  Given owner is on class scheduling page
  When they click "Create Single Class"
  And they select class type "Reformer Pilates"
  And they select instructor "Sarah Johnson"
  And they select room "Studio A"
  And they set date "2025-12-15"
  And they set start time "10:00 AM"
  And they set capacity "8 clients"
  And they click "Create Class"
  Then class session is created
  And class appears in calendar
  And class is available for booking
  And instructor receives notification

Scenario: [Edge Case] Create class outside business hours
  Given business hours are 6am-8pm
  When owner creates class at 9pm
  Then warning shows "This class is outside your business hours"
  And owner can confirm to proceed
  Or cancel to reschedule

Scenario: [Error Case] Instructor double-booking
  Given instructor has class at 10am
  When owner tries to schedule same instructor at 10am
  Then error shows "Instructor is already scheduled for this time"
```

### Acceptance Criteria

1. Form: class type, instructor, room, date, time, capacity
2. Date picker (only future dates)
3. Time picker in 15-minute increments
4. Capacity defaults from class type, can be overridden
5. Validation: no double-booking instructor
6. Validation: no double-booking room
7. Validation: capacity doesn't exceed room capacity
8. Warning for scheduling outside business hours
9. Class immediately available for booking
10. Instructor notification sent

### Technical Implementation

**Domain**: Classes

**Ash Resource**:
```elixir
# lib/pilates_on_phx/classes/class_session.ex
create :create_single_session do
  accept [:class_type_id, :instructor_id, :room_id, :start_time, :capacity]

  validate future_date(:start_time)
  validate unique_instructor_time()
  validate unique_room_time()
  validate capacity_within_room_limit()

  change set_end_time_from_class_type()
  change set_initial_available_spots()
  change notify_instructor()
end
```

**LiveView**: `PilatesOnPhxWeb.Classes.CreateSingleLive`

**References**:
- `/Users/wlstory/src/PilatesOnPhx/lib/pilates_on_phx/classes/class_session.ex`
- `/Users/wlstory/src/PilatesOnPhx/AGENTS.md` - Ash validations (lines 1200-1300)

### Testing Strategy

- Test class creation with valid data
- Test double-booking prevention (instructor)
- Test double-booking prevention (room)
- Test capacity validation
- Test instructor notification
- 85%+ coverage

### Dependencies

- PHX-4: Classes Domain (ClassSession resource)
- PHX-17: Class types must exist
- PHX-18: Rooms must exist
- Instructor resource must exist

### Definition of Done

- [ ] Class creation working
- [ ] All validations enforced
- [ ] Double-booking prevented
- [ ] Instructor notifications sent
- [ ] Tests passing
- [ ] Code reviewed
- [ ] Deployed

---

## PHX-21: Recurring Class Series Creation

**Type**: Story
**Priority**: 2 (High)
**Labels**: scheduling, classes-domain, recurring, sprint-2
**Parent**: PHX-11
**Project**: Sprint 2 - Core User Workflows

### Title
Recurring Class Series Creation

### User Story
As a studio owner, I want to create a recurring class series (e.g., every Tuesday at 10am), so that I don't have to manually create each class session.

### Description

Core scheduling feature - create recurring class series with flexible recurrence patterns (daily, weekly, monthly).

**Context**: Most studios operate on recurring schedules. This dramatically reduces administrative overhead.

### Use Cases

```gherkin
Scenario: [Happy Path] Create weekly recurring class
  Given owner is on class scheduling page
  When they click "Create Recurring Series"
  And they select class type "Mat Pilates"
  And they select instructor "Jane Doe"
  And they select room "Studio B"
  And they set recurrence pattern "Weekly"
  And they select day "Tuesday"
  And they set time "10:00 AM"
  And they set start date "2025-12-01"
  And they set end date "2026-06-01" (6 months)
  And they click "Create Series"
  Then recurring series is created
  And 26 individual class sessions are generated
  And all sessions appear in calendar
  And success message shows "26 classes created"

Scenario: [Edge Case] Series with holidays
  Given owner creates recurring series
  And they select "Skip Studio Holidays"
  When series includes Dec 25 (holiday)
  Then class on Dec 25 is not created
  And other classes in series are created

Scenario: [Error Case] End date before start date
  Given owner sets start date "2025-12-01"
  When they set end date "2025-11-01"
  Then error shows "End date must be after start date"
```

### Acceptance Criteria

1. Recurrence pattern selector: Daily, Weekly, Monthly
2. For weekly: select days of week (checkboxes)
3. For monthly: select day of month or "Last Tuesday" patterns
4. Start date and end date pickers
5. "No end date" option (creates 3 months ahead, rolls forward)
6. "Skip Studio Holidays" checkbox
7. Preview: "This will create X classes"
8. Validation: end date after start date
9. Validation: at least one day selected for weekly
10. Bulk creation in database transaction

### Technical Implementation

**Domain**: Classes

**Ash Resource**:
```elixir
# lib/pilates_on_phx/classes/recurring_series.ex
attributes do
  attribute :recurrence_pattern, :atom # :daily, :weekly, :monthly
  attribute :recurrence_config, :map # {days: [:tuesday, :thursday]}
  attribute :start_date, :date
  attribute :end_date, :date
  attribute :skip_holidays, :boolean
end

create :create_series do
  accept [:class_type_id, :instructor_id, :room_id, :recurrence_pattern, :recurrence_config, :start_date, :end_date]

  validate end_date_after_start_date()
  validate valid_recurrence_config()

  change generate_class_sessions()
  change associate_sessions_to_series()
end
```

**LiveView**: `PilatesOnPhxWeb.Classes.CreateRecurringLive`

**References**:
- `/Users/wlstory/src/PilatesOnPhx/lib/pilates_on_phx/classes/recurring_series.ex`
- `/Users/wlstory/src/PilatesOnPhx/AGENTS.md` - Bulk operations (lines 1400-1500)

### Testing Strategy

- Test weekly recurrence generation
- Test daily recurrence
- Test monthly recurrence
- Test holiday skipping
- Test end date validation
- Test bulk session creation
- 85%+ coverage

### Dependencies

- PHX-4: Classes Domain (RecurringSeries, ClassSession resources)
- PHX-20: Single class creation (reuses logic)

### Definition of Done

- [ ] Recurrence patterns working
- [ ] Session generation accurate
- [ ] Holiday skipping functional
- [ ] Validations enforced
- [ ] Bulk creation efficient
- [ ] Tests passing
- [ ] Code reviewed
- [ ] Deployed

---

## PHX-22: Edit Recurring Class Series

**Type**: Story
**Priority**: 2 (High)
**Labels**: scheduling, classes-domain, recurring, sprint-2
**Parent**: PHX-11
**Project**: Sprint 2 - Core User Workflows

### Title
Edit Recurring Class Series

### User Story
As a studio owner, I want to edit a recurring class series (change time, instructor, or room), so that I can adapt the schedule without recreating the entire series.

### Description

Essential maintenance feature - modify existing recurring series with options to apply changes to future sessions only or all sessions.

**Context**: Schedules change frequently (instructor availability, room changes). Must handle sessions with existing bookings carefully.

### Use Cases

```gherkin
Scenario: [Happy Path] Change instructor for future sessions
  Given a recurring series "Tuesday Mat Pilates at 10am"
  And series has 10 future sessions and 5 past sessions
  When owner clicks "Edit Series"
  And they change instructor from "Jane" to "Sarah"
  And they select "Apply to future sessions only"
  And they click "Save Changes"
  Then future 10 sessions are updated with new instructor
  And past 5 sessions remain unchanged
  And both instructors receive notifications

Scenario: [Edge Case] Change time of series with bookings
  Given series has sessions with existing bookings
  When owner changes time from 10am to 11am
  Then warning shows "X sessions have bookings. Clients will be notified."
  And owner can confirm or cancel
  If confirmed, clients receive rescheduling email

Scenario: [Error Case] Change creates instructor conflict
  Given owner changes time to 2pm
  When new instructor is already scheduled at 2pm
  Then error shows "Instructor conflict on dates: Dec 1, Dec 8, Dec 15"
  And changes are not applied
```

### Acceptance Criteria

1. Edit form: modify class type, instructor, room, time, capacity
2. Two options: "Apply to future sessions" or "Apply to all sessions"
3. Preview: "This will affect X sessions"
4. Warning if sessions have bookings
5. Validation: no conflicts created
6. Bulk update in transaction
7. Notifications sent to affected instructors
8. Notifications sent to clients if time/date changes
9. Audit trail of changes
10. Can revert changes if needed

### Technical Implementation

**Domain**: Classes

**Ash Resource**:
```elixir
# lib/pilates_on_phx/classes/recurring_series.ex
update :edit_series do
  accept [:class_type_id, :instructor_id, :room_id, :time]
  argument :apply_to, :atom # :future_only, :all_sessions

  validate no_conflicts_created()

  change bulk_update_sessions()
  change notify_affected_parties()
  change log_audit_trail()
end
```

**LiveView**: `PilatesOnPhxWeb.Classes.EditRecurringLive`

**References**:
- `/Users/wlstory/src/PilatesOnPhx/lib/pilates_on_phx/classes/recurring_series.ex`

### Testing Strategy

- Test future-only updates
- Test all-sessions updates
- Test conflict detection
- Test booking notifications
- Test audit trail
- 85%+ coverage

### Dependencies

- PHX-21: Recurring series must exist
- PHX-28: Bookings (to check for conflicts)

### Definition of Done

- [ ] Edit form working
- [ ] Future-only vs all-sessions logic correct
- [ ] Conflict detection working
- [ ] Notifications sent
- [ ] Audit trail created
- [ ] Tests passing
- [ ] Code reviewed
- [ ] Deployed

---

## PHX-23: Cancel/Delete Recurring Series

**Type**: Story
**Priority**: 2 (High)
**Labels**: scheduling, classes-domain, recurring, sprint-2
**Parent**: PHX-11
**Project**: Sprint 2 - Core User Workflows

### Title
Cancel/Delete Recurring Series

### User Story
As a studio owner, I want to cancel or delete a recurring class series, so that I can remove classes that are no longer offered or need to be rescheduled.

### Description

Critical administrative function - safely remove recurring series with proper handling of existing bookings and client refunds.

**Context**: Must handle booked sessions carefully - cancel vs delete distinction important. Cancelled classes can be reinstated; deleted are permanent.

### Use Cases

```gherkin
Scenario: [Happy Path] Cancel future sessions only
  Given a recurring series with 8 future sessions
  And 3 of those sessions have bookings
  When owner clicks "Cancel Series"
  And they select "Cancel future sessions only"
  And they confirm cancellation
  Then future sessions marked as cancelled
  And clients with bookings receive refunds per policy
  And clients receive cancellation notifications
  And series remains in database (audit trail)

Scenario: [Edge Case] Delete series with no bookings
  Given a recurring series with 0 bookings
  When owner clicks "Delete Series"
  And they confirm deletion
  Then all sessions are hard-deleted from database
  And series record is deleted
  And success message shows "Series deleted"

Scenario: [Error Case] Try to delete past sessions with bookings
  Given series has past sessions with attendance records
  When owner tries to delete series
  Then error shows "Cannot delete series with historical attendance"
  And owner is offered "Cancel future sessions" option
```

### Acceptance Criteria

1. Two options: "Cancel" (soft delete) vs "Delete" (hard delete)
2. Sub-options: "Future sessions only" or "All sessions"
3. Warning if sessions have bookings: "X bookings will be refunded"
4. Preview: "This will affect X sessions and Y bookings"
5. Confirmation dialog with summary
6. Cancelled sessions: marked cancelled, not deleted
7. Deleted sessions: removed from database (only if no bookings)
8. Refunds issued automatically per cancellation policy
9. Clients receive cancellation emails
10. Audit trail maintained

### Technical Implementation

**Domain**: Classes

**Ash Resource**:
```elixir
# lib/pilates_on_phx/classes/recurring_series.ex
update :cancel_series do
  argument :cancel_scope, :atom # :future_only, :all_sessions
  argument :reason, :string

  validate cannot_delete_with_attendance()

  change mark_sessions_cancelled()
  change process_refunds()
  change notify_affected_clients()
  change log_cancellation()
end

destroy :delete_series do
  validate no_bookings_exist()

  change hard_delete_sessions()
  change log_deletion()
end
```

**LiveView**: `PilatesOnPhxWeb.Classes.CancelSeriesLive`

**References**:
- `/Users/wlstory/src/PilatesOnPhx/lib/pilates_on_phx/classes/recurring_series.ex`

### Testing Strategy

- Test cancel future-only
- Test cancel all sessions
- Test delete with no bookings
- Test cannot delete with bookings
- Test refund processing
- Test client notifications
- 85%+ coverage

### Dependencies

- PHX-21: Recurring series must exist
- PHX-28: Bookings (for refund processing)
- PHX-30: Cancellation logic (reuses refund policy)

### Definition of Done

- [ ] Cancel vs delete logic working
- [ ] Refund processing functional
- [ ] Validations prevent inappropriate deletions
- [ ] Notifications sent
- [ ] Audit trail created
- [ ] Tests passing
- [ ] Code reviewed
- [ ] Deployed

---

## PHX-24: Class Calendar View

**Type**: Story
**Priority**: 2 (High)
**Labels**: scheduling, classes-domain, ui, sprint-2
**Parent**: PHX-11
**Project**: Sprint 2 - Core User Workflows

### Title
Class Calendar View

### User Story
As a studio owner or instructor, I want to view all scheduled classes in a calendar interface, so that I can visualize the schedule and identify conflicts or gaps.

### Description

Essential visualization tool - display all scheduled classes in month, week, and day views with real-time capacity indicators.

**Context**: Primary scheduling interface for staff. Must show capacity, instructor, room, and booking status at a glance.

### Use Cases

```gherkin
Scenario: [Happy Path] Owner views weekly calendar
  Given owner navigates to class schedule page
  When they select "Week View"
  Then calendar displays current week (Mon-Sun)
  And each class shows: time, name, instructor, capacity (5/8)
  And classes are color-coded by class type
  And owner can click class to view details
  And owner can drag class to reschedule

Scenario: [Edge Case] View past classes with attendance
  Given owner views past week
  Then past classes show attendance: "7 attended, 1 no-show"
  And past classes cannot be edited
  And past classes are displayed in muted colors

Scenario: [Error Case] Calendar fails to load
  Given network error occurs
  When calendar tries to load
  Then error message shows "Unable to load schedule"
  And retry button is displayed
  And cached data is shown if available
```

### Acceptance Criteria

1. Three view modes: Month, Week, Day
2. Filter by: instructor, room, class type
3. Real-time capacity indicators (5/8 available)
4. Color-coding by class type
5. Visual indicators: full (red), nearly full (yellow), available (green)
6. Click class to view/edit details
7. Drag-and-drop to reschedule (future classes only)
8. "Today" button to jump to current date
9. Navigation: prev/next buttons, date picker
10. Responsive design (mobile-friendly)

### Technical Implementation

**Domain**: Classes

**LiveView with Streams**:
```elixir
# lib/pilates_on_phx_web/live/classes/calendar_live.ex
defmodule PilatesOnPhxWeb.Classes.CalendarLive do
  use PilatesOnPhxWeb, :live_view

  def mount(_params, _session, socket) do
    # Subscribe to class updates
    Phoenix.PubSub.subscribe(PilatesOnPhx.PubSub, "studio:#{studio_id}:classes")

    {:ok, socket
      |> assign(view_mode: :week, current_date: Date.utc_today())
      |> stream(:classes, load_classes())
    }
  end

  def handle_event("change_view", %{"mode" => mode}, socket) do
    {:noreply, assign(socket, view_mode: String.to_atom(mode))}
  end

  def handle_info({:class_updated, class}, socket) do
    {:noreply, stream_insert(socket, :classes, class)}
  end
end
```

**Calendar Component**:
- Use FullCalendar.js or custom LiveView calendar
- Phoenix.Component for calendar grid
- Tailwind CSS for styling

**References**:
- `/Users/wlstory/src/PilatesOnPhx/lib/pilates_on_phx_web/live/classes/calendar_live.ex`
- `/Users/wlstory/src/PilatesOnPhx/AGENTS.md` - LiveView streams (lines 550-650)

### Testing Strategy

- Test calendar rendering (month/week/day)
- Test filtering
- Test real-time updates via PubSub
- Test drag-and-drop reschedule
- LiveViewTest for interactions
- 85%+ coverage

### Dependencies

- PHX-20: Single classes must exist
- PHX-21: Recurring series creates classes
- Phoenix.PubSub for real-time updates

### Definition of Done

- [ ] All three views working
- [ ] Filtering functional
- [ ] Real-time updates working
- [ ] Drag-and-drop reschedule working
- [ ] Responsive design
- [ ] Tests passing
- [ ] Code reviewed
- [ ] Deployed

---

## PHX-25: Client Registration & Profile

**Type**: Story
**Priority**: 1 (Urgent)
**Labels**: booking, clients-domain, sprint-2
**Parent**: PHX-12
**Project**: Sprint 2 - Core User Workflows

### Title
Client Registration & Profile Setup

### User Story
As a new client, I want to register for an account and create my profile, so that I can book classes at the studio.

### Description

Client onboarding - create user account with client role, profile information, emergency contacts, and preferences.

**Original Source**: Extracted from WLS-60 (Booking workflow)

**Context**: First step in the booking workflow. Client profile must exist before purchasing packages or booking classes.

### Use Cases

```gherkin
Scenario: [Happy Path] Client registers with email/password
  Given a new client visits the studio's booking page
  When they click "Sign Up"
  And they enter email "client@example.com"
  And they enter password "SecurePass123!"
  And they enter name "John Smith"
  And they enter phone "(555) 123-4567"
  And they accept Terms of Service
  And they click "Create Account"
  Then User record is created with role "client"
  And Client profile is created
  And verification email is sent
  And they are redirected to "Complete Your Profile" page

Scenario: [Happy Path] Client completes profile with emergency contact
  Given client has basic account
  When they complete profile form
  And they enter emergency contact name "Jane Smith"
  And they enter emergency phone "(555) 987-6543"
  And they enter health notes "Knee injury - left knee"
  And they click "Save Profile"
  Then profile is updated
  And success message shows "Profile complete!"
  And they are redirected to package purchase page

Scenario: [Error Case] Duplicate email registration
  Given a user with email "client@example.com" exists
  When new client tries to register with same email
  Then error shows "Email already registered. Sign in instead?"
  And "Forgot password?" link is shown
```

### Acceptance Criteria

1. Email/password registration using AshAuthentication
2. Basic info: name, phone, date of birth (optional)
3. Emergency contact: name, phone, relationship
4. Health notes field (injuries, medical conditions)
5. Preferences: email notifications, SMS reminders
6. Profile photo upload (optional)
7. Email verification required
8. Terms of Service acceptance
9. Privacy policy acceptance
10. Can edit profile later in account settings

### Technical Implementation

**Domain**: Clients (or Bookings)

**Ash Resources**:
```elixir
# lib/pilates_on_phx/clients/client.ex
defmodule PilatesOnPhx.Clients.Client do
  attributes do
    attribute :name, :string
    attribute :phone, :string
    attribute :date_of_birth, :date
    attribute :emergency_contact, :map
    attribute :health_notes, :string
    attribute :preferences, :map
    attribute :profile_photo_url, :string
  end

  relationships do
    belongs_to :user, PilatesOnPhx.Accounts.User
    belongs_to :studio, PilatesOnPhx.Studios.Studio
  end

  create :register do
    accept [:name, :phone, :emergency_contact, :health_notes]

    validate present([:name, :phone])
    validate phone_format(:phone)
  end
end
```

**LiveView**: `PilatesOnPhxWeb.Clients.RegisterLive`
**LiveView**: `PilatesOnPhxWeb.Clients.ProfileLive`

**References**:
- `/Users/wlstory/src/PilatesOnPhx/lib/pilates_on_phx/clients/client.ex`
- `/Users/wlstory/src/PilatesOnPhx/docs/product-management/SPRINT_2_ISSUES_TO_CREATE.md` (lines 117-138)

### Testing Strategy

- Test client registration
- Test profile completion
- Test emergency contact validation
- Test duplicate email handling
- Test email verification
- 85%+ coverage

### Dependencies

- PHX-2: Accounts Domain (User)
- PHX-12: Epic parent

### Definition of Done

- [ ] Client registration working
- [ ] Profile form functional
- [ ] Emergency contact capture working
- [ ] Email verification implemented
- [ ] Tests passing
- [ ] Code reviewed
- [ ] Deployed

---

## PHX-26: Package Purchase with Stripe Integration

**Type**: Story
**Priority**: 1 (Urgent)
**Labels**: booking, payments, stripe, sprint-2, critical
**Parent**: PHX-12
**Project**: Sprint 2 - Core User Workflows

### Title
Package Purchase with Stripe Integration

### User Story
As a client, I want to purchase a credit package using my credit card, so that I can book classes at the studio.

### Description

CRITICAL REVENUE FEATURE - Stripe payment integration for package purchases. Handles payment processing, credit allocation, and package activation.

**Original Source**: Extracted from WLS-98 (Package Conversion), core booking workflow

**Context**: This is the primary revenue driver. Payment must be atomic with credit allocation. Must handle payment failures gracefully.

### Use Cases

```gherkin
Scenario: [Happy Path] Client purchases 10-class package
  Given client is logged in
  And client has no packages
  When they navigate to "Purchase Package" page
  And they select "10-Class Package - $150"
  And they click "Purchase"
  And they enter credit card details via Stripe Elements
  And they click "Complete Payment"
  Then Stripe processes payment
  And Payment record is created with status "completed"
  And ClientPackage is created with 10 credits
  And client receives email receipt
  And they are redirected to class browser
  And success message shows "Package purchased! You have 10 credits."

Scenario: [Edge Case] Payment requires 3D Secure authentication
  Given client's card requires 3D Secure
  When they complete payment
  Then Stripe shows 3D Secure modal
  And client completes authentication
  And payment is processed after authentication
  And package is activated

Scenario: [Error Case] Payment declined
  Given client enters card that will be declined
  When they submit payment
  Then Stripe returns decline error
  And Payment record is created with status "failed"
  And error shows "Payment declined. Please try another card."
  And client can retry with different card
  And no credits are allocated
```

### Acceptance Criteria

1. Package selection page with pricing
2. Stripe Elements integration for card input
3. Support for 3D Secure (SCA compliance)
4. Payment processing indicators ("Processing...")
5. Atomic transaction: payment + credit allocation
6. Payment statuses: pending, completed, failed, refunded
7. Email receipt sent on success
8. Error handling for payment failures
9. Retry mechanism for failed payments
10. Package expiration date calculated (e.g., 6 months from purchase)

### Technical Implementation

**Domain**: Bookings (or Payments)

**Stripe Integration**:
```elixir
# lib/pilates_on_phx/bookings/stripe_service.ex
defmodule PilatesOnPhx.Bookings.StripeService do
  def create_payment_intent(package, client) do
    Stripe.PaymentIntent.create(%{
      amount: package.price_cents,
      currency: "usd",
      customer: client.stripe_customer_id,
      metadata: %{
        client_id: client.id,
        package_id: package.id,
        studio_id: package.studio_id
      },
      automatic_payment_methods: %{enabled: true}
    })
  end

  def confirm_payment_and_allocate_credits(payment_intent_id, client, package) do
    Ash.Changeset.new()
    |> Ecto.Multi.new()
    |> Multi.run(:payment, fn _, _ ->
      # Verify payment succeeded
      {:ok, payment_intent} = Stripe.PaymentIntent.retrieve(payment_intent_id)
      if payment_intent.status == "succeeded" do
        create_payment_record(payment_intent)
      else
        {:error, :payment_not_completed}
      end
    end)
    |> Multi.run(:package, fn _, %{payment: payment} ->
      # Allocate credits
      create_client_package(client, package, payment)
    end)
    |> Repo.transaction()
  end
end
```

**Ash Resources**:
```elixir
# lib/pilates_on_phx/bookings/payment.ex
attributes do
  attribute :amount_cents, :integer
  attribute :stripe_payment_intent_id, :string
  attribute :status, :atom # :pending, :completed, :failed, :refunded
  attribute :payment_type, :atom # :package_purchase, :refund
end

# lib/pilates_on_phx/bookings/client_package.ex
attributes do
  attribute :remaining_credits, :integer
  attribute :purchased_at, :utc_datetime
  attribute :expires_at, :utc_datetime
end

create :purchase_package do
  argument :payment_intent_id, :string

  validate payment_succeeded()

  change allocate_credits()
  change set_expiration()
  change send_receipt_email()
end
```

**LiveView**: `PilatesOnPhxWeb.Packages.PurchaseLive`

**References**:
- `/Users/wlstory/src/PilatesOnPhx/lib/pilates_on_phx/bookings/stripe_service.ex`
- `/Users/wlstory/src/PilatesOnPhx/docs/product-management/SPRINT_2_ISSUES_TO_CREATE.md` (lines 140-165, 239-248)
- Stripe API docs: https://stripe.com/docs/payments/payment-intents

### Testing Strategy

- Test successful payment flow (use Stripe test mode)
- Test payment decline handling
- Test 3D Secure flow (use Stripe test cards)
- Test atomic transaction (payment + credits)
- Test retry after failure
- Test webhook handling for async payment confirmation
- 85%+ coverage

### Dependencies

- PHX-25: Client must be registered
- Stripe account with API keys configured
- Stripe Elements library

### Definition of Done

- [ ] Stripe Elements integrated
- [ ] Payment processing working
- [ ] 3D Secure supported
- [ ] Atomic credit allocation working
- [ ] Error handling comprehensive
- [ ] Tests passing (Stripe test mode)
- [ ] Webhooks configured
- [ ] Code reviewed
- [ ] Security audit complete
- [ ] Deployed

---

## PHX-27: Browse Available Classes with Real-Time Capacity

**Type**: Story
**Priority**: 1 (Urgent)
**Labels**: booking, classes-domain, real-time, sprint-2
**Parent**: PHX-12
**Project**: Sprint 2 - Core User Workflows

### Title
Browse Available Classes with Real-Time Capacity

### User Story
As a client, I want to browse available classes with real-time capacity information, so that I can find and book classes that fit my schedule.

### Description

Primary booking interface - display upcoming classes with live capacity updates via Phoenix PubSub. Foundation for the booking workflow.

**Original Source**: Extracted from WLS-60 (Booking workflow)

**Context**: Real-time capacity is critical to prevent overbooking. Clients must see accurate availability instantly.

### Use Cases

```gherkin
Scenario: [Happy Path] Client browses classes with filters
  Given client is logged in
  And client has 5 available credits
  When they navigate to "Browse Classes" page
  Then they see list of upcoming classes
  And each class shows: name, instructor, time, capacity "5/8 available"
  When they filter by "Reformer Pilates"
  Then only Reformer classes are shown
  When they filter by "Tuesday"
  Then only Tuesday classes are shown

Scenario: [Real-Time] Capacity updates live
  Given client is viewing class list
  And a class shows "1/8 available"
  When another client books that class
  Then capacity updates to "0/8 available - FULL"
  And "Join Waitlist" button appears
  And update happens without page refresh

Scenario: [Edge Case] No classes available
  Given studio has no classes scheduled in next 7 days
  When client browses classes
  Then message shows "No classes scheduled. Check back soon!"
  And option to view past classes is shown
```

### Acceptance Criteria

1. List view of upcoming classes (next 7 days by default)
2. Each class shows: type, instructor, date, time, duration, capacity
3. Real-time capacity updates via Phoenix PubSub
4. Filters: date range, class type, instructor, day of week
5. Sort options: date, time, availability
6. "Book Now" button (if spots available)
7. "Join Waitlist" button (if full)
8. "Fully Booked" badge on full classes
9. "Almost Full" badge when 80% capacity
10. Pagination or infinite scroll

### Technical Implementation

**Domain**: Classes, Bookings

**LiveView with PubSub**:
```elixir
# lib/pilates_on_phx_web/live/classes/browse_live.ex
defmodule PilatesOnPhxWeb.Classes.BrowseLive do
  use PilatesOnPhxWeb, :live_view

  def mount(_params, session, socket) do
    # Subscribe to capacity updates
    studio_id = get_studio_id(session)
    Phoenix.PubSub.subscribe(PilatesOnPhx.PubSub, "studio:#{studio_id}:classes")

    classes = load_upcoming_classes(studio_id)

    {:ok, socket
      |> assign(filters: %{}, sort_by: :date)
      |> stream(:classes, classes)
    }
  end

  def handle_info({:class_capacity_changed, class_id, new_capacity}, socket) do
    # Update specific class in stream
    updated_class = reload_class(class_id)
    {:noreply, stream_insert(socket, :classes, updated_class)}
  end

  def handle_event("filter", %{"class_type" => type}, socket) do
    # Apply filters and reload
    {:noreply, reload_with_filters(socket, %{class_type: type})}
  end
end
```

**Ash Query**:
```elixir
# Load classes with capacity calculations
PilatesOnPhx.Classes.ClassSession
|> Ash.Query.filter(start_time > ^DateTime.utc_now())
|> Ash.Query.filter(start_time < ^seven_days_from_now())
|> Ash.Query.load([:class_type, :instructor, :room])
|> Ash.Query.load([:bookings_count, :available_spots])
|> Ash.Query.sort(start_time: :asc)
|> PilatesOnPhx.Classes.read!()
```

**Calculations**:
```elixir
# lib/pilates_on_phx/classes/class_session.ex
calculations do
  calculate :bookings_count, :integer do
    expr(count(bookings, query: [filter: status == :confirmed]))
  end

  calculate :available_spots, :integer do
    expr(capacity - bookings_count)
  end

  calculate :is_full, :boolean do
    expr(available_spots <= 0)
  end
end
```

**References**:
- `/Users/wlstory/src/PilatesOnPhx/lib/pilates_on_phx_web/live/classes/browse_live.ex`
- `/Users/wlstory/src/PilatesOnPhx/AGENTS.md` - Phoenix PubSub patterns (lines 700-800)
- `/Users/wlstory/src/PilatesOnPhx/docs/product-management/SPRINT_2_ISSUES_TO_CREATE.md` (lines 230-235)

### Testing Strategy

- Test class list rendering
- Test filtering functionality
- Test real-time capacity updates via PubSub
- Test "Full" vs "Available" states
- LiveViewTest for interactions
- 85%+ coverage

### Dependencies

- PHX-20: Classes must be scheduled
- PHX-25: Client must be logged in
- Phoenix.PubSub configured

### Definition of Done

- [ ] Class browser rendering correctly
- [ ] Filters working
- [ ] Real-time capacity updates working
- [ ] PubSub integration functional
- [ ] Tests passing
- [ ] Performance optimized (< 1s load time)
- [ ] Code reviewed
- [ ] Deployed

---

## PHX-28: Book Class with Package Credits (Atomic Operation)

**Type**: Story
**Priority**: 1 (Urgent)
**Labels**: booking, core-workflow, atomic-transaction, sprint-2, critical
**Parent**: PHX-12
**Project**: Sprint 2 - Core User Workflows

### Title
Book Class with Package Credits (Atomic Operation)

### User Story
As a client, I want to book a class using my package credits, so that I can reserve my spot in the class.

### Description

**MOST CRITICAL FEATURE** - Atomic booking transaction that deducts credits and creates booking simultaneously. Must prevent race conditions and double-booking.

**Original Source**: WLS-60 (Recurring Booking), core booking workflow

**Context**: This is the heart of the booking system. MUST be atomic to prevent credit leakage and overbooking. Database-level transaction required.

### Use Cases

```gherkin
Scenario: [Happy Path] Client books class successfully
  Given client has 5 available credits
  And class "Reformer Pilates Tue 10am" has 3 available spots
  When client clicks "Book Now"
  Then database transaction begins
  And 1 credit is deducted from client's package
  And booking record is created with status "confirmed"
  And class capacity is decremented by 1
  And transaction commits
  And client receives confirmation email
  And instructor is notified
  And class capacity updates in real-time for all viewers
  And success message shows "Class booked! You have 4 credits remaining."

Scenario: [Edge Case] Concurrent booking race condition
  Given class has 1 available spot
  And Client A and Client B try to book simultaneously
  When both click "Book Now" at the exact same time
  Then database transaction uses row-level locking
  And only 1 booking succeeds (Client A)
  And Client B receives error "Class is now full. Join waitlist?"
  And Client B's credits are not deducted
  And consistency is maintained

Scenario: [Error Case] Insufficient credits
  Given client has 0 available credits
  When they try to book a class
  Then error shows "Insufficient credits. Purchase a package to continue."
  And "Purchase Package" button is displayed
  And booking is not created
```

### Acceptance Criteria

1. "Book Now" button on class browser and class detail pages
2. Validation: client has sufficient credits
3. Validation: class has available spots
4. Atomic transaction: credit deduction + booking creation + capacity decrement
5. Database row-level locking to prevent race conditions
6. Booking status: confirmed
7. Confirmation email sent to client
8. Instructor notification
9. Real-time capacity broadcast via PubSub
10. Success message with remaining credits displayed

### Technical Implementation

**Domain**: Bookings

**Atomic Booking Action**:
```elixir
# lib/pilates_on_phx/bookings/booking.ex
create :book_class do
  argument :client_id, :uuid, allow_nil?: false
  argument :class_session_id, :uuid, allow_nil?: false

  # Validations
  validate validate_sufficient_credits()
  validate validate_class_capacity()
  validate validate_not_already_booked()

  # Atomic changes (all or nothing)
  change deduct_credits()  # Decrements client_package.remaining_credits
  change decrement_capacity()  # Decrements class_session.available_spots
  change set_booking_status(:confirmed)
  change broadcast_capacity_update()  # PubSub
  change send_confirmation_email()
  change notify_instructor()

  # Use database transaction with SERIALIZABLE isolation
  change transaction_isolation_level(:serializable)
end
```

**Credit Deduction Change**:
```elixir
defmodule DeductCredits do
  use Ash.Resource.Change

  def change(changeset, _opts, context) do
    client_id = Ash.Changeset.get_argument(changeset, :client_id)

    # Get client's non-expired package with credits
    package = PilatesOnPhx.Bookings.ClientPackage
      |> Ash.Query.filter(client_id == ^client_id)
      |> Ash.Query.filter(remaining_credits > 0)
      |> Ash.Query.filter(expires_at > ^DateTime.utc_now())
      |> Ash.Query.sort(expires_at: :asc)  # Use oldest first
      |> Ash.Query.limit(1)
      |> PilatesOnPhx.Bookings.read_one!()

    if is_nil(package) do
      Ash.Changeset.add_error(changeset, "Insufficient credits")
    else
      # Atomic decrement with optimistic locking
      package
      |> Ash.Changeset.for_update(:deduct_credit, %{})
      |> Ash.update!()

      Ash.Changeset.manage_relationship(changeset, :client_package, package, type: :append)
    end
  end
end
```

**Database Migration for Row-Level Locking**:
```sql
-- Ensure capacity never goes negative
ALTER TABLE class_sessions
ADD CONSTRAINT capacity_non_negative CHECK (available_spots >= 0);

-- Index for concurrent booking performance
CREATE INDEX CONCURRENTLY idx_class_sessions_available_spots
ON class_sessions (id, available_spots)
WHERE available_spots > 0;
```

**LiveView**:
```elixir
# lib/pilates_on_phx_web/live/bookings/book_class_live.ex
def handle_event("book_class", %{"class_id" => class_id}, socket) do
  client = socket.assigns.current_client

  case PilatesOnPhx.Bookings.Booking
       |> Ash.Changeset.for_create(:book_class, %{
         client_id: client.id,
         class_session_id: class_id
       }, actor: socket.assigns.current_user)
       |> Ash.create() do
    {:ok, booking} ->
      {:noreply, socket
        |> put_flash(:info, "Class booked! You have #{booking.credits_remaining} credits remaining.")
        |> push_navigate(to: ~p"/bookings/#{booking.id}")
      }

    {:error, %Ash.Error.Invalid{errors: [%{message: "Insufficient credits"}]}} ->
      {:noreply, socket
        |> put_flash(:error, "Insufficient credits. Purchase a package to continue.")
        |> push_navigate(to: ~p"/packages/purchase")
      }

    {:error, %Ash.Error.Invalid{errors: [%{message: msg}]}} when msg =~ "full" ->
      {:noreply, socket
        |> put_flash(:info, "Class is now full. Would you like to join the waitlist?")
        |> push_navigate(to: ~p"/classes/#{class_id}/waitlist")
      }
  end
end
```

**References**:
- `/Users/wlstory/src/PilatesOnPhx/lib/pilates_on_phx/bookings/booking.ex`
- `/Users/wlstory/src/PilatesOnPhx/AGENTS.md` - Ecto transactions (lines 1100-1200)
- `/Users/wlstory/src/PilatesOnPhx/docs/product-management/SPRINT_2_ISSUES_TO_CREATE.md` (lines 166-194, 239-248)

### Testing Strategy

**CRITICAL - Must test race conditions**:
- Test successful booking with credit deduction
- Test concurrent bookings (spawn multiple processes)
- Test insufficient credits error
- Test class full error
- Test idempotency (double-click prevention)
- Test transaction rollback on failure
- Test PubSub broadcast
- Stress test with 100 concurrent bookings
- 90%+ coverage (critical path)

### Dependencies

- PHX-26: Client must have purchased package
- PHX-27: Client browsing classes
- PHX-12: Epic parent
- PostgreSQL with row-level locking support

### Definition of Done

- [ ] Atomic booking transaction working
- [ ] Race condition tests passing
- [ ] Credit deduction validated
- [ ] Capacity decrement working
- [ ] PubSub broadcast functional
- [ ] Notifications sent
- [ ] Stress tests passing (0% credit leakage)
- [ ] Code reviewed
- [ ] Security audit complete
- [ ] Deployed

---

## PHX-29: Join Waitlist When Class Full

**Type**: Story
**Priority**: 1 (Urgent)
**Labels**: booking, waitlist, sprint-2
**Parent**: PHX-12
**Project**: Sprint 2 - Core User Workflows

### Title
Join Waitlist When Class Full

### User Story
As a client, I want to join a waitlist when a class is full, so that I can be automatically notified if a spot opens up.

### Description

Waitlist management system - automatically add clients to waitlist when class is full, track position, and promote to booking when spot opens.

**Original Source**: Extracted from WLS-60 (Booking workflow), WLS-67 (Cancellation triggers waitlist)

**Context**: Waitlist prevents lost bookings and improves client satisfaction. Auto-promotion on cancellation is critical.

### Use Cases

```gherkin
Scenario: [Happy Path] Client joins waitlist for full class
  Given class "Reformer Pilates" has 0 available spots
  And 2 clients are already on waitlist
  When client clicks "Join Waitlist"
  Then waitlist entry is created
  And position is calculated as 3
  And confirmation shows "You're #3 on the waitlist"
  And client receives waitlist confirmation email
  And no credits are deducted

Scenario: [Happy Path] Client promoted from waitlist
  Given client is #1 on waitlist
  When another client cancels their booking 48 hours before class
  Then spot becomes available
  And client #1 receives notification "A spot opened up!"
  And client has 24 hours to confirm booking
  And if confirmed, booking is created and credits deducted
  And if not confirmed within 24hrs, next person on waitlist is notified

Scenario: [Edge Case] Multiple cancellations at once
  Given class has 3 cancellations simultaneously
  And 5 clients on waitlist
  Then clients #1, #2, #3 are all notified
  And each has 24-hour window to confirm
  And confirmations are processed in order
```

### Acceptance Criteria

1. "Join Waitlist" button appears when class full
2. Waitlist position calculated automatically
3. Confirmation message shows position
4. No credits deducted for waitlist join
5. Client receives waitlist confirmation email
6. Auto-promotion when spot opens (from cancellation)
7. 24-hour confirmation window for promoted clients
8. Notification email sent on promotion
9. If not confirmed in 24hrs, next person promoted
10. Client can leave waitlist anytime (no penalty)

### Technical Implementation

**Domain**: Bookings

**Ash Resource**:
```elixir
# lib/pilates_on_phx/bookings/waitlist.ex
defmodule PilatesOnPhx.Bookings.Waitlist do
  attributes do
    attribute :position, :integer
    attribute :joined_at, :utc_datetime
    attribute :notified_at, :utc_datetime
    attribute :expires_at, :utc_datetime  # 24 hours after notification
    attribute :status, :atom  # :waiting, :notified, :confirmed, :expired, :removed
  end

  relationships do
    belongs_to :client, PilatesOnPhx.Clients.Client
    belongs_to :class_session, PilatesOnPhx.Classes.ClassSession
  end

  create :join do
    accept [:client_id, :class_session_id]

    validate class_is_full()
    validate not_already_on_waitlist()

    change calculate_position()  # Max position + 1
    change set_status(:waiting)
    change send_waitlist_confirmation()
  end

  update :promote do
    accept []

    change set_status(:notified)
    change set_notified_at()
    change set_expires_at(hours: 24)
    change send_promotion_notification()
  end

  update :confirm do
    accept []

    change create_booking()  # Calls booking.book_class
    change set_status(:confirmed)
    change remove_from_waitlist()
  end
end
```

**Auto-Promotion Logic** (triggered by booking cancellation):
```elixir
# lib/pilates_on_phx/bookings/booking.ex (in cancel action)
update :cancel do
  change refund_credits()
  change increment_capacity()
  change promote_next_on_waitlist()  # Key change
end

defmodule PromoteNextOnWaitlist do
  use Ash.Resource.Change

  def change(changeset, _opts, _context) do
    class_session_id = Ash.Changeset.get_attribute(changeset, :class_session_id)

    # Get next person on waitlist
    next_waitlisted = PilatesOnPhx.Bookings.Waitlist
      |> Ash.Query.filter(class_session_id == ^class_session_id)
      |> Ash.Query.filter(status == :waiting)
      |> Ash.Query.sort(position: :asc)
      |> Ash.Query.limit(1)
      |> PilatesOnPhx.Bookings.read_one()

    if next_waitlisted do
      next_waitlisted
      |> Ash.Changeset.for_update(:promote, %{})
      |> Ash.update!()
    end

    changeset
  end
end
```

**Expiration Job** (Oban):
```elixir
# lib/pilates_on_phx/bookings/jobs/expire_waitlist_notifications.ex
defmodule PilatesOnPhx.Bookings.Jobs.ExpireWaitlistNotifications do
  use Oban.Worker, queue: :waitlist

  def perform(%{}) do
    # Find expired notifications
    expired = PilatesOnPhx.Bookings.Waitlist
      |> Ash.Query.filter(status == :notified)
      |> Ash.Query.filter(expires_at < ^DateTime.utc_now())
      |> PilatesOnPhx.Bookings.read!()

    Enum.each(expired, fn waitlist ->
      # Mark as expired
      waitlist
      |> Ash.Changeset.for_update(:expire, %{})
      |> Ash.update!()

      # Promote next person
      promote_next_on_waitlist(waitlist.class_session_id)
    end)

    :ok
  end
end
```

**LiveView**:
```elixir
# lib/pilates_on_phx_web/live/waitlist/join_live.ex
def handle_event("join_waitlist", %{"class_id" => class_id}, socket) do
  case PilatesOnPhx.Bookings.Waitlist
       |> Ash.Changeset.for_create(:join, %{
         client_id: socket.assigns.current_client.id,
         class_session_id: class_id
       })
       |> Ash.create() do
    {:ok, waitlist} ->
      {:noreply, socket
        |> put_flash(:info, "You're ##{waitlist.position} on the waitlist. We'll notify you if a spot opens!")
        |> push_navigate(to: ~p"/bookings")
      }

    {:error, _} ->
      {:noreply, put_flash(socket, :error, "Unable to join waitlist. Please try again.")}
  end
end
```

**References**:
- `/Users/wlstory/src/PilatesOnPhx/lib/pilates_on_phx/bookings/waitlist.ex`
- `/Users/wlstory/src/PilatesOnPhx/docs/product-management/SPRINT_2_ISSUES_TO_CREATE.md` (lines 196-204)

### Testing Strategy

- Test waitlist join
- Test position calculation
- Test auto-promotion on cancellation
- Test 24-hour expiration
- Test multiple promotions
- Test Oban job execution
- 85%+ coverage

### Dependencies

- PHX-28: Booking must exist
- PHX-30: Cancellation triggers promotion
- Oban for background jobs

### Definition of Done

- [ ] Waitlist join working
- [ ] Position calculation accurate
- [ ] Auto-promotion functional
- [ ] 24-hour expiration working
- [ ] Oban job configured
- [ ] Notifications sent
- [ ] Tests passing
- [ ] Code reviewed
- [ ] Deployed

---

## PHX-30: Cancel Booking with Policy-Based Refund

**Type**: Story
**Priority**: 1 (Urgent)
**Labels**: booking, cancellation, refund-policy, sprint-2
**Parent**: PHX-12
**Project**: Sprint 2 - Core User Workflows

### Title
Cancel Booking with Policy-Based Refund

### User Story
As a client, I want to cancel my booking, so that I can free up the spot and receive a credit refund based on the cancellation policy.

### Description

Critical client feature - cancel bookings with policy-based refund calculation. Triggers waitlist promotion.

**Original Source**: WLS-67 (Cancel Booking)

**Context**: Cancellation policy varies by studio. Must calculate refund based on time before class. Atomic transaction: refund + capacity increment + waitlist promotion.

### Use Cases

```gherkin
Scenario: [Happy Path] Client cancels booking early (full refund)
  Given client has booking for "Reformer Pilates" on Tuesday at 10am
  And current time is Monday at 5pm (17 hours before class)
  And studio cancellation policy is "Full refund if 12+ hours before"
  When client clicks "Cancel Booking"
  And they confirm cancellation
  Then booking status changes to "cancelled"
  And 1 credit is refunded to client's package
  And class capacity increments by 1
  And next person on waitlist is promoted
  And client receives cancellation confirmation email

Scenario: [Edge Case] Client cancels late (partial refund)
  Given client has booking for class in 6 hours
  And studio policy is "50% refund if 6-12 hours before, no refund if <6 hours"
  When client cancels at 7 hours before
  Then booking is cancelled
  And 0.5 credits refunded (50%)
  And capacity incremented
  And waitlist promoted

Scenario: [Error Case] Client tries to cancel after class started
  Given class start time was 5 minutes ago
  When client tries to cancel
  Then error shows "Cannot cancel after class has started"
  And booking remains confirmed
```

### Acceptance Criteria

1. "Cancel Booking" button on booking details page
2. Confirmation dialog: "Are you sure? Refund: X credits based on policy"
3. Refund calculation based on cancellation policy and time before class
4. Refund amounts: 100%, 50%, or 0% based on policy
5. Atomic transaction: refund + capacity + waitlist promotion
6. Booking status changes to "cancelled"
7. Cannot cancel after class has started
8. Cannot cancel no-show bookings
9. Client receives cancellation confirmation email
10. Cancellation reason field (optional)

### Technical Implementation

**Domain**: Bookings

**Ash Resource**:
```elixir
# lib/pilates_on_phx/bookings/booking.ex
update :cancel do
  accept [:cancellation_reason]

  validate cannot_cancel_after_start()
  validate cannot_cancel_no_show()

  change calculate_refund_by_policy()
  change refund_credits()
  change increment_class_capacity()
  change promote_next_on_waitlist()
  change set_status(:cancelled)
  change send_cancellation_email()
  change log_cancellation()
end
```

**Refund Calculation**:
```elixir
defmodule CalculateRefundByPolicy do
  use Ash.Resource.Change

  def change(changeset, _opts, _context) do
    booking = changeset.data
    class_session = Ash.load!(booking, :class_session).class_session
    studio = Ash.load!(class_session, [:studio]).studio

    hours_before_class = DateTime.diff(class_session.start_time, DateTime.utc_now(), :hour)

    refund_percent = case studio.settings.cancellation_policy do
      %{hours_before: threshold, refund_percent: percent} ->
        if hours_before_class >= threshold, do: percent, else: 0

      # More complex policies with tiers
      %{tiers: tiers} ->
        Enum.find_value(tiers, 0, fn %{hours_before: h, refund_percent: p} ->
          if hours_before_class >= h, do: p
        end)
    end

    refund_amount = booking.credits_used * (refund_percent / 100)

    Ash.Changeset.change_attribute(changeset, :refund_amount, refund_amount)
  end
end
```

**LiveView**:
```elixir
# lib/pilates_on_phx_web/live/bookings/cancel_live.ex
def handle_event("cancel_booking", %{"booking_id" => booking_id}, socket) do
  booking = load_booking(booking_id)
  refund_info = calculate_refund_preview(booking)

  socket = assign(socket,
    booking: booking,
    refund_amount: refund_info.amount,
    refund_policy: refund_info.policy_text,
    show_confirmation_modal: true
  )

  {:noreply, socket}
end

def handle_event("confirm_cancel", %{"booking_id" => booking_id}, socket) do
  case PilatesOnPhx.Bookings.Booking
       |> Ash.Changeset.for_update(:cancel, %{}, actor: socket.assigns.current_user)
       |> Ash.update() do
    {:ok, booking} ->
      {:noreply, socket
        |> put_flash(:info, "Booking cancelled. #{booking.refund_amount} credits refunded.")
        |> push_navigate(to: ~p"/bookings")
      }

    {:error, %{message: msg}} ->
      {:noreply, put_flash(socket, :error, msg)}
  end
end
```

**References**:
- `/Users/wlstory/src/PilatesOnPhx/lib/pilates_on_phx/bookings/booking.ex`
- `/Users/wlstory/src/PilatesOnPhx/docs/product-management/SPRINT_2_ISSUES_TO_CREATE.md` (lines 189-194)

### Testing Strategy

- Test full refund scenario (early cancellation)
- Test partial refund scenario (late cancellation)
- Test no refund scenario (very late)
- Test cannot cancel after class started
- Test waitlist promotion triggered
- Test refund calculation with various policies
- 85%+ coverage

### Dependencies

- PHX-28: Booking must exist
- PHX-29: Waitlist promotion logic
- PHX-16: Studio cancellation policy configured

### Definition of Done

- [ ] Cancellation working
- [ ] Refund calculation accurate
- [ ] Policy tiers supported
- [ ] Atomic transaction functional
- [ ] Waitlist promotion triggered
- [ ] Validation prevents inappropriate cancellations
- [ ] Tests passing
- [ ] Code reviewed
- [ ] Deployed

---

## PHX-31: Staff Batch Check-In Interface

**Type**: Story
**Priority**: 1 (Urgent)
**Labels**: booking, check-in, staff-tools, sprint-2
**Parent**: PHX-12
**Project**: Sprint 2 - Core User Workflows

### Title
Staff Batch Check-In Interface

### User Story
As a studio staff member or instructor, I want to check in multiple clients at once, so that I can efficiently record attendance at the start of class.

### Description

Essential staff tool - batch check-in interface for marking attendance. Displays booking list for a class with one-click check-in.

**Original Source**: WLS-71 (Check-In)

**Context**: Staff need quick, efficient check-in at class start. Mobile-friendly interface critical for tablet use at front desk.

### Use Cases

```gherkin
Scenario: [Happy Path] Staff checks in multiple clients
  Given instructor opens check-in page for "Reformer Pilates 10am"
  And class has 7 confirmed bookings
  When page loads, booking list is displayed
  And each client shows: name, booking status
  When instructor taps "Check In" next to "Sarah Johnson"
  Then Sarah's status changes to "attended"
  And checkmark appears next to her name
  When instructor taps "Check In All Remaining"
  Then all remaining clients marked as "attended"
  And attendance is saved

Scenario: [Edge Case] Client arrives late
  Given class started 15 minutes ago
  And client "John Smith" was marked "no-show"
  When client arrives and staff checks them in
  Then status changes from "no-show" to "attended (late)"
  And late arrival is recorded

Scenario: [Error Case] No-show tracking
  Given class ended 1 hour ago
  And 2 clients were not checked in
  When system runs post-class job
  Then unchecked clients marked as "no-show"
  And studio no-show policy applies (e.g., credit not refunded)
```

### Acceptance Criteria

1. Check-in page for specific class session
2. List of all confirmed bookings with client names
3. "Check In" button next to each client (large touch target)
4. "Check In All" button for bulk check-in
5. Real-time status updates (no page refresh needed)
6. Visual indicators: checked-in (green), not checked-in (gray), no-show (red)
7. Can undo check-in if mistake
8. Mobile-responsive design (tablet-optimized)
9. Can access check-in up to 30 minutes before class start
10. Post-class automatic no-show marking (Oban job)

### Technical Implementation

**Domain**: Bookings

**Ash Resource**:
```elixir
# lib/pilates_on_phx/bookings/booking.ex
update :check_in do
  accept [:checked_in_at]

  validate class_time_window()  # Must be within 30 min before to end time

  change set_status(:attended)
  change set_checked_in_at()
end

update :mark_no_show do
  accept []

  change set_status(:no_show)
  change apply_no_show_policy()  # May forfeit credit
end
```

**LiveView with Streams**:
```elixir
# lib/pilates_on_phx_web/live/staff/check_in_live.ex
defmodule PilatesOnPhxWeb.Staff.CheckInLive do
  use PilatesOnPhxWeb, :live_view

  def mount(%{"class_id" => class_id}, _session, socket) do
    class_session = load_class_with_bookings(class_id)

    {:ok, socket
      |> assign(class_session: class_session)
      |> stream(:bookings, class_session.bookings)
    }
  end

  def handle_event("check_in", %{"booking_id" => booking_id}, socket) do
    booking = load_booking(booking_id)

    case booking
         |> Ash.Changeset.for_update(:check_in, %{
           checked_in_at: DateTime.utc_now()
         }, actor: socket.assigns.current_user)
         |> Ash.update() do
      {:ok, updated_booking} ->
        {:noreply, stream_insert(socket, :bookings, updated_booking)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to check in")}
    end
  end

  def handle_event("check_in_all", _, socket) do
    bookings = socket.assigns.bookings

    Enum.each(bookings, fn booking ->
      if booking.status != :attended do
        booking
        |> Ash.Changeset.for_update(:check_in, %{checked_in_at: DateTime.utc_now()})
        |> Ash.update!()
      end
    end)

    {:noreply, socket
      |> put_flash(:info, "All clients checked in")
      |> push_navigate(to: ~p"/staff/dashboard")
    }
  end
end
```

**Oban Job for No-Shows**:
```elixir
# lib/pilates_on_phx/bookings/jobs/mark_no_shows.ex
defmodule PilatesOnPhx.Bookings.Jobs.MarkNoShows do
  use Oban.Worker, queue: :attendance

  def perform(%{"class_session_id" => class_session_id}) do
    # Find bookings that were not checked in
    no_shows = PilatesOnPhx.Bookings.Booking
      |> Ash.Query.filter(class_session_id == ^class_session_id)
      |> Ash.Query.filter(status == :confirmed)
      |> Ash.Query.filter(is_nil(checked_in_at))
      |> PilatesOnPhx.Bookings.read!()

    Enum.each(no_shows, fn booking ->
      booking
      |> Ash.Changeset.for_update(:mark_no_show, %{})
      |> Ash.update!()
    end)

    :ok
  end
end

# Schedule job 30 minutes after class end time
defmodule ScheduleNoShowJob do
  def schedule_for_class(class_session) do
    run_at = DateTime.add(class_session.end_time, 30, :minute)

    %{class_session_id: class_session.id}
    |> PilatesOnPhx.Bookings.Jobs.MarkNoShows.new(scheduled_at: run_at)
    |> Oban.insert()
  end
end
```

**References**:
- `/Users/wlstory/src/PilatesOnPhx/lib/pilates_on_phx_web/live/staff/check_in_live.ex`
- `/Users/wlstory/src/PilatesOnPhx/AGENTS.md` - LiveView streams (lines 550-650)

### Testing Strategy

- Test individual check-in
- Test bulk check-in
- Test undo check-in
- Test no-show marking (Oban job)
- Test time window validation
- LiveViewTest for interactions
- 85%+ coverage

### Dependencies

- PHX-28: Bookings must exist
- PHX-20: Class sessions scheduled
- Oban for background jobs

### Definition of Done

- [ ] Check-in interface working
- [ ] Bulk check-in functional
- [ ] Real-time updates working
- [ ] Mobile-responsive design
- [ ] Oban job configured
- [ ] No-show marking working
- [ ] Tests passing
- [ ] Code reviewed
- [ ] Deployed

---

## PHX-32: Package Conversion Request & Approval

**Type**: Story
**Priority**: 1 (Urgent)
**Labels**: booking, packages, admin-tools, sprint-2
**Parent**: PHX-12
**Project**: Sprint 2 - Core User Workflows

### Title
Package Conversion Request & Approval

### User Story
As a client, I want to request a package conversion (e.g., convert unused credits to a different package type), so that I can adapt my package to my changing needs.

**Context from Epic**: Some studios allow package conversions (e.g., convert 10-class pack to monthly unlimited). This requires admin approval and may involve price adjustments.

### Description

Administrative workflow - clients can request package conversions, studio staff review and approve/deny with optional price adjustments.

**Original Source**: WLS-98 (Package Conversion)

**Context**: Package conversions are complex business logic. Must handle credit transfers, expiration dates, and price differences.

### Use Cases

```gherkin
Scenario: [Happy Path] Client requests package conversion
  Given client has "10-Class Package" with 5 remaining credits
  And client wants to switch to "Monthly Unlimited"
  When they navigate to "My Packages"
  And they click "Request Conversion"
  And they select target package "Monthly Unlimited"
  And they enter reason "My schedule changed, need more flexibility"
  And they submit request
  Then conversion request is created with status "pending"
  And studio owner receives notification
  And client sees "Request pending approval"

Scenario: [Happy Path] Owner approves conversion with price adjustment
  Given conversion request from client exists
  And original package cost $150, used $75 worth (5 of 10 credits)
  And new package costs $200/month
  When owner reviews request
  And they approve conversion
  And they set price adjustment "$50 additional payment required"
  Then client receives approval notification with payment link
  And when client pays $50, conversion completes
  And old package is deactivated
  And new package is activated

Scenario: [Edge Case] Owner denies conversion
  Given conversion request exists
  When owner denies with reason "Policy doesn't allow conversions"
  Then client receives denial notification
  And original package remains active
```

### Acceptance Criteria

1. "Request Conversion" button on package details page
2. Form: target package, reason for conversion
3. Conversion request status: pending, approved, denied, completed
4. Admin review interface for studio owners
5. Price adjustment calculation (credit remaining value vs new package cost)
6. Approval can include additional payment required
7. Denial includes reason
8. Notifications for request, approval, denial
9. Payment link if additional payment required (Stripe integration)
10. Audit trail of all conversions

### Technical Implementation

**Domain**: Bookings

**Ash Resource**:
```elixir
# lib/pilates_on_phx/bookings/package_conversion_request.ex
defmodule PilatesOnPhx.Bookings.PackageConversionRequest do
  attributes do
    attribute :status, :atom  # :pending, :approved, :denied, :completed
    attribute :reason, :string
    attribute :price_adjustment_cents, :integer
    attribute :admin_notes, :string
  end

  relationships do
    belongs_to :client, PilatesOnPhx.Clients.Client
    belongs_to :original_package, PilatesOnPhx.Bookings.ClientPackage
    belongs_to :target_package_type, PilatesOnPhx.Bookings.Package
    belongs_to :reviewed_by, PilatesOnPhx.Accounts.User
  end

  create :request_conversion do
    accept [:client_id, :original_package_id, :target_package_type_id, :reason]

    validate original_package_has_credits()

    change calculate_price_adjustment()
    change set_status(:pending)
    change notify_studio_owner()
  end

  update :approve do
    accept [:admin_notes, :price_adjustment_cents]
    argument :reviewed_by_id, :uuid

    change set_status(:approved)
    change set_reviewed_by()
    change notify_client_approval()
    change create_payment_link_if_needed()
  end

  update :deny do
    accept [:admin_notes]
    argument :reviewed_by_id, :uuid

    change set_status(:denied)
    change set_reviewed_by()
    change notify_client_denial()
  end

  update :complete do
    change deactivate_original_package()
    change create_new_package()
    change transfer_credits()
    change set_status(:completed)
  end
end
```

**LiveView - Client Request**:
```elixir
# lib/pilates_on_phx_web/live/packages/conversion_request_live.ex
def handle_event("submit_request", params, socket) do
  case PilatesOnPhx.Bookings.PackageConversionRequest
       |> Ash.Changeset.for_create(:request_conversion, params, actor: socket.assigns.current_user)
       |> Ash.create() do
    {:ok, request} ->
      {:noreply, socket
        |> put_flash(:info, "Conversion request submitted. You'll be notified when reviewed.")
        |> push_navigate(to: ~p"/packages")
      }

    {:error, _} ->
      {:noreply, put_flash(socket, :error, "Failed to submit request")}
  end
end
```

**LiveView - Admin Review**:
```elixir
# lib/pilates_on_phx_web/live/admin/conversion_review_live.ex
def handle_event("approve", %{"request_id" => id, "adjustment" => adjustment}, socket) do
  request = load_request(id)

  case request
       |> Ash.Changeset.for_update(:approve, %{
         price_adjustment_cents: String.to_integer(adjustment) * 100,
         reviewed_by_id: socket.assigns.current_user.id
       }, actor: socket.assigns.current_user)
       |> Ash.update() do
    {:ok, _} ->
      {:noreply, socket
        |> put_flash(:info, "Conversion approved")
        |> push_navigate(to: ~p"/admin/conversions")
      }

    {:error, _} ->
      {:noreply, put_flash(socket, :error, "Failed to approve")}
  end
end
```

**References**:
- `/Users/wlstory/src/PilatesOnPhx/lib/pilates_on_phx/bookings/package_conversion_request.ex`

### Testing Strategy

- Test conversion request creation
- Test approval workflow
- Test denial workflow
- Test price adjustment calculation
- Test credit transfer on completion
- Test Stripe payment for price adjustment
- 85%+ coverage

### Dependencies

- PHX-26: Client packages must exist
- PHX-12: Epic parent
- Stripe for additional payments

### Definition of Done

- [ ] Request creation working
- [ ] Admin review interface functional
- [ ] Approval/denial workflows working
- [ ] Price adjustment calculation accurate
- [ ] Credit transfer working
- [ ] Notifications sent
- [ ] Tests passing
- [ ] Code reviewed
- [ ] Deployed

---

## PHX-33: Attendance Tracking & Reports

**Type**: Story
**Priority**: 1 (Urgent)
**Labels**: booking, reporting, analytics, sprint-2
**Parent**: PHX-12
**Project**: Sprint 2 - Core User Workflows

### Title
Attendance Tracking & Reports

### User Story
As a studio owner, I want to view attendance reports and client attendance history, so that I can analyze class popularity and client engagement.

### Description

Reporting and analytics feature - generate attendance reports by class, instructor, client, and time period.

**Context**: Attendance data informs business decisions (popular class times, instructor performance, client engagement). Foundation for future analytics features.

### Use Cases

```gherkin
Scenario: [Happy Path] Owner views class attendance report
  Given owner navigates to "Reports > Attendance"
  When they select date range "Last 30 days"
  And they filter by class type "Reformer Pilates"
  Then report shows:
    - Total classes: 24
    - Total bookings: 180
    - Average attendance: 7.5 clients per class
    - No-show rate: 5%
    - Most popular time: Tuesday 10am
    - Least popular time: Friday 6pm

Scenario: [Happy Path] Owner views instructor performance
  Given owner filters report by instructor "Sarah Johnson"
  When they view last 30 days
  Then report shows:
    - Classes taught: 16
    - Total attendance: 120
    - Average class size: 7.5
    - Client retention: 80% (repeat clients)
    - Client feedback scores: 4.8/5

Scenario: [Edge Case] Client views own attendance history
  Given client logs in
  When they navigate to "My Attendance"
  Then they see list of attended classes
  And attendance streak: "5 classes this month"
  And no-show count: 1
  And credits used: 12
```

### Acceptance Criteria

1. Reports page with date range selector
2. Filter options: class type, instructor, room, client
3. Metrics displayed:
   - Total classes held
   - Total bookings
   - Total attendance (checked-in)
   - No-show rate
   - Average class size
   - Popular times/days
4. Export to CSV
5. Visual charts (bar chart for attendance over time)
6. Client-facing: personal attendance history
7. Drill-down: click class to see attendee list
8. Performance metrics by instructor
9. Client engagement metrics (streaks, frequency)
10. Caching for expensive queries

### Technical Implementation

**Domain**: Bookings, Reports (new domain?)

**Ash Calculations**:
```elixir
# lib/pilates_on_phx/reports/attendance_report.ex
defmodule PilatesOnPhx.Reports.AttendanceReport do
  # Virtual resource for reporting
  use Ash.Resource, data_layer: :embedded

  calculations do
    calculate :total_bookings, :integer do
      # Count bookings in date range
    end

    calculate :attendance_rate, :float do
      expr((total_attended / total_bookings) * 100)
    end

    calculate :no_show_rate, :float do
      expr((total_no_shows / total_bookings) * 100)
    end

    calculate :average_class_size, :float do
      expr(total_attended / total_classes)
    end
  end

  actions do
    read :generate do
      argument :start_date, :date
      argument :end_date, :date
      argument :class_type_id, :uuid
      argument :instructor_id, :uuid

      prepare fn query, _context ->
        # Build complex aggregation query
        # Use Ash.Query aggregate functions
      end
    end
  end
end
```

**LiveView with Charts**:
```elixir
# lib/pilates_on_phx_web/live/reports/attendance_live.ex
defmodule PilatesOnPhxWeb.Reports.AttendanceLive do
  use PilatesOnPhxWeb, :live_view

  def mount(_params, _session, socket) do
    report = generate_attendance_report(
      start_date: Date.add(Date.utc_today(), -30),
      end_date: Date.utc_today()
    )

    {:ok, socket
      |> assign(report: report)
      |> assign(chart_data: format_for_chart(report))
    }
  end

  def handle_event("filter", %{"start_date" => start_date, "end_date" => end_date}, socket) do
    report = generate_attendance_report(
      start_date: Date.from_iso8601!(start_date),
      end_date: Date.from_iso8601!(end_date)
    )

    {:noreply, assign(socket, report: report)}
  end

  def handle_event("export_csv", _, socket) do
    csv_content = generate_csv(socket.assigns.report)

    {:noreply, push_event(socket, "download", %{
      filename: "attendance_report_#{Date.utc_today()}.csv",
      content: csv_content
    })}
  end
end
```

**CSV Export**:
```elixir
defmodule PilatesOnPhx.Reports.CsvExporter do
  def export_attendance(report_data) do
    headers = ["Date", "Class", "Instructor", "Booked", "Attended", "No-Shows"]

    rows = Enum.map(report_data, fn row ->
      [row.date, row.class_name, row.instructor, row.booked, row.attended, row.no_shows]
    end)

    [headers | rows]
    |> CSV.encode()
    |> Enum.to_list()
    |> Enum.join()
  end
end
```

**Charting** (use Contex or Chart.js):
```elixir
# Use Contex for server-rendered charts
alias Contex.{BarChart, Plot}

def render_attendance_chart(data) do
  dataset = Dataset.new(data, ["Date", "Attendance"])

  BarChart.new(dataset)
  |> BarChart.set_val_col_names(["Attendance"])
  |> Plot.new(500, 400, "Attendance Over Time")
  |> Plot.to_svg()
end
```

**References**:
- `/Users/wlstory/src/PilatesOnPhx/lib/pilates_on_phx/reports/attendance_report.ex`
- `/Users/wlstory/src/PilatesOnPhx/AGENTS.md` - Ash calculations (lines 1300-1400)

### Testing Strategy

- Test report generation with various filters
- Test date range calculations
- Test CSV export format
- Test calculations (attendance rate, no-show rate)
- Test performance with large datasets
- 85%+ coverage

### Dependencies

- PHX-31: Check-in data must exist
- PHX-28: Booking data
- PHX-20: Class sessions

### Definition of Done

- [ ] Report generation working
- [ ] All metrics calculated correctly
- [ ] Filtering functional
- [ ] CSV export working
- [ ] Charts rendering
- [ ] Performance optimized
- [ ] Tests passing
- [ ] Code reviewed
- [ ] Deployed

---

## Summary

**Total Issues Created**: 23 (1 Epic + 22 Stories)

### Breakdown by Epic

**Epic PHX-10 (Onboarding)** - 7 stories:
- PHX-13: Studio Basic Information Capture
- PHX-14: Owner Account Initial Setup
- PHX-15: Business Model Selection
- PHX-16: Studio Configuration Settings
- PHX-17: Class Types Setup
- PHX-18: Rooms & Facilities Management
- PHX-19: Equipment Inventory

**Epic PHX-11 (Scheduling)** - 5 stories:
- PHX-20: Create Single Class Session
- PHX-21: Recurring Class Series Creation
- PHX-22: Edit Recurring Class Series
- PHX-23: Cancel/Delete Recurring Series
- PHX-24: Class Calendar View

**Epic PHX-12 (Booking)** - 9 stories:
- PHX-25: Client Registration & Profile
- PHX-26: Package Purchase with Stripe
- PHX-27: Browse Available Classes
- PHX-28: Book Class with Credits (CRITICAL)
- PHX-29: Join Waitlist When Full
- PHX-30: Cancel Booking
- PHX-31: Staff Batch Check-In
- PHX-32: Package Conversion Request
- PHX-33: Attendance Tracking

### Priority Distribution
- **Priority 1 (Urgent)**: 16 stories (Onboarding + Booking)
- **Priority 2 (High)**: 5 stories (Scheduling)

### Critical Path Stories
- PHX-14: Owner Account (authentication foundation)
- PHX-26: Package Purchase (revenue)
- PHX-28: Book Class (core transaction)

### Next Steps

1. **Create in Linear**: Use the comprehensive specifications above to create each issue
2. **Assign Parent IDs**: Link PHX-13 to PHX-19 to PHX-10, PHX-20 to PHX-24 to PHX-11, PHX-25 to PHX-33 to PHX-12
3. **Set Project**: All issues to "Sprint 2 - Core User Workflows"
4. **Set Team**: All issues to "AltBuild-PHX"
5. **Verify**: Total 23 issues created

---

**Document Created**: 2025-11-11
**Ready for Linear Issue Creation**
