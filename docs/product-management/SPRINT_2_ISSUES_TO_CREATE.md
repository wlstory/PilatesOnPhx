# Sprint 2 Issues - Ready to Create in Linear

This document contains all Sprint 2 user stories ready to be created in Linear under the AltBuild-PHX team.

## Summary

- **Project**: Sprint 2 - Core User Workflows (ID: 9f2b68bd-c266-4da0-b220-bd05196f3124)
- **Total Issues**: 21 user stories across 3 epics
- **Epics Created**:
  - PHX-10: Studio Onboarding & Setup Wizard ✅
  - PHX-11: Class Scheduling & Recurring Classes ✅
  - Need to create: Epic for Booking Workflow

---

## Epic PHX-12: Booking Workflow & Package Management

**Project**: Sprint 2 - Core User Workflows
**Priority**: Urgent (1)
**Labels**: epic, booking, core-workflow, sprint-2, critical

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

#### Use Cases

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

#### Phoenix/Elixir/Ash Implementation

##### Domain: Bookings

##### Ash Resources

```elixir
# Client - Profile and preferences
defmodule PilatesOnPhx.Bookings.Client do
  attributes do
    attribute :emergency_contact, :map
    attribute :preferences, :map
    attribute :notes, :string
  end

  relationships do
    belongs_to :user, PilatesOnPhx.Accounts.User
    belongs_to :studio, PilatesOnPhx.Studios.Studio
    has_many :client_packages, PilatesOnPhx.Bookings.ClientPackage
    has_many :bookings, PilatesOnPhx.Bookings.Booking
  end

  calculations do
    calculate :available_credits, :integer do
      # Sum remaining_credits from non-expired packages
    end
  end
end

# Package - Package type definitions
defmodule PilatesOnPhx.Bookings.Package do
  attributes do
    attribute :name, :string
    attribute :total_credits, :integer
    attribute :price_cents, :integer
    attribute :expiration_days, :integer
    attribute :package_type, :atom # :class_pack, :monthly_unlimited
  end
end

# ClientPackage - Purchased package instance
defmodule PilatesOnPhx.Bookings.ClientPackage do
  attributes do
    attribute :remaining_credits, :integer
    attribute :purchased_at, :utc_datetime
    attribute :expires_at, :utc_datetime
  end

  calculations do
    calculate :is_expired, :boolean do
      expr(expires_at < now())
    end
  end
end

# Booking - Class reservation
defmodule PilatesOnPhx.Bookings.Booking do
  attributes do
    attribute :status, :atom # :confirmed, :cancelled, :no_show
    attribute :credits_used, :integer, default: 1
    attribute :booked_at, :utc_datetime
  end

  actions do
    create :book_class do
      argument :client_id, :uuid
      argument :class_session_id, :uuid

      # Atomic transaction
      validate validate_sufficient_credits()
      validate validate_class_capacity()
      change deduct_credits()  # Must succeed with booking
      change decrement_capacity()
      change broadcast_capacity_update()
      change send_confirmation()
    end

    update :cancel do
      change refund_credits_by_policy()
      change promote_waitlist()
      change send_cancellation_notice()
    end
  end
end

# Waitlist - Waitlist entries
defmodule PilatesOnPhx.Bookings.Waitlist do
  attributes do
    attribute :position, :integer
    attribute :joined_at, :utc_datetime
    attribute :notified_at, :utc_datetime
    attribute :expires_at, :utc_datetime
  end

  actions do
    create :join do
      change calculate_position()
    end

    update :promote do
      change send_notification()
      change set_expiration(hours: 24)
    end
  end
end

# Payment - Payment records
defmodule PilatesOnPhx.Bookings.Payment do
  attributes do
    attribute :amount_cents, :integer
    attribute :stripe_payment_intent_id, :string
    attribute :status, :atom # :pending, :completed, :failed, :refunded
    attribute :payment_type, :atom # :package_purchase, :refund
  end
end
```

##### LiveView Components

- `BookingLive.ClassBrowser` - Browse classes with filters and real-time capacity
- `BookingLive.BookFlow` - Complete booking workflow
- `PackageLive.Purchase` - Package purchase with Stripe Elements
- `CheckInLive.BatchCheckIn` - Staff batch check-in interface
- `AttendanceLive.Report` - Attendance history and reports

##### Stripe Integration

```elixir
defmodule PilatesOnPhx.Bookings.StripeService do
  def create_payment_intent(amount_cents, client_id) do
    Stripe.PaymentIntent.create(%{
      amount: amount_cents,
      currency: "usd",
      metadata: %{client_id: client_id}
    })
  end
end
```

##### PubSub Topics

- `"studio:#{studio_id}:classes"` - Class capacity updates
- `"client:#{client_id}:bookings"` - Booking confirmations
- `"class:#{class_id}:waitlist"` - Waitlist changes

#### User Stories (Children)

- PHX-13: Client Registration & Profile Setup
- PHX-14: Package Purchase with Stripe Integration
- PHX-15: Browse Available Classes with Real-Time Capacity
- PHX-16: Book Class with Package Credits (Atomic Operation)
- PHX-17: Join Waitlist When Class Full
- PHX-18: Cancel Booking with Policy-Based Refund
- PHX-19: Staff Batch Check-In Interface
- PHX-20: Package Conversion Request & Approval
- PHX-21: Attendance Tracking & Reports

#### Dependencies

- PHX-2: Accounts Domain (User)
- PHX-3: Studios Domain (Studio)
- PHX-4: Classes Domain (ClassSession)
- PHX-9: Bookings Domain resources defined
- PHX-11: Class Scheduling (for browsing classes)

#### Testing Strategy

- Test atomic booking transaction (credit deduction + booking creation)
- Test concurrent booking race conditions
- Test waitlist promotion logic
- Test cancellation policy (early vs late)
- Test Stripe payment flow (use test mode)
- LiveViewTest for booking UI
- Integration tests for complete workflows
- 85%+ coverage on business logic

#### Success Criteria

- 95%+ booking success rate (no race conditions)
- < 2 seconds for booking confirmation
- Zero credit leakage (atomic operations)
- Waitlist promotion < 5 minutes
- Stripe payment success rate > 98%

#### References

- Original: WLS-67, WLS-71, WLS-98, WLS-60
- AGENTS.md: LiveView patterns, Ecto transactions
- Stripe API docs: https://stripe.com/docs/api

---

## User Stories for Epic PHX-10 (Studio Onboarding)

### PHX-13: Studio Basic Information Capture (Step 1)

**Parent**: PHX-10
**Project**: Sprint 2 - Core User Workflows
**Priority**: Urgent (1)
**Labels**: onboarding, studios-domain, sprint-2

**Original Source**: WLS-102 (NextJS)

#### User Story

As a Studio Owner
I want to enter basic studio information during onboarding
So that my studio profile is created with correct contact details and branding

#### Use Cases

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

#### Acceptance Criteria

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

#### Phoenix/Elixir/Ash Implementation

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

**LiveView Component**:
```elixir
# lib/pilates_on_phx_web/live/onboarding/basic_info_live.ex
defmodule PilatesOnPhxWeb.Onboarding.BasicInfoLive do
  use PilatesOnPhxWeb, :live_view

  def mount(_params, session, socket) do
    # Load progress from session if exists
    progress = session["onboarding_progress"] || %{}

    {:ok, assign(socket,
      form: to_form(changeset),
      step: 1,
      total_steps: 6
    )}
  end

  def handle_event("validate", %{"studio" => params}, socket) do
    # Real-time validation
  end

  def handle_event("save_and_continue", %{"studio" => params}, socket) do
    # Create studio, advance to step 2
  end

  def handle_event("save_and_exit", %{"studio" => params}, socket) do
    # Save to session, redirect to dashboard
  end
end
```

**File Upload**:
```elixir
# Use Phoenix.LiveView.UploadConfig
allow_upload(:logo,
  accept: ~w(.jpg .jpeg .png .svg),
  max_entries: 1,
  max_file_size: 2_000_000
)

# Upload to Supabase Storage or S3
def handle_progress(:logo, entry, socket) do
  if entry.done? do
    uploaded_file = consume_uploaded_entry(socket, entry, fn %{path: path} ->
      dest = Path.join("uploads/logos", "#{entry.uuid}.#{ext(entry)}")
      File.cp!(path, dest)
      {:ok, "/uploads/logos/#{entry.uuid}.#{ext(entry)}"}
    end)

    {:noreply, assign(socket, logo_url: uploaded_file)}
  else
    {:noreply, socket}
  end
end
```

#### Dependencies

- PHX-3: Studios Domain (Studio resource)
- PHX-10: Epic parent

#### Testing Strategy

- LiveViewTest for form interactions
- Test validation rules (phone, email, URL)
- Test file upload (mock upload)
- Test save-and-exit functionality
- Test form pre-population on resume
- 85%+ coverage

#### Definition of Done

- [ ] All acceptance criteria met
- [ ] Form validation working
- [ ] File upload functional
- [ ] Tests passing (85%+ coverage)
- [ ] LiveView component renders correctly
- [ ] Onboarding progress tracking works
- [ ] Code reviewed
- [ ] Deployed to staging

---

### PHX-14: Owner Account Initial Setup (Step 2)

**Parent**: PHX-10
**Project**: Sprint 2 - Core User Workflows
**Priority**: Urgent (1)
**Labels**: onboarding, accounts-domain, authentication, sprint-2

**Original Source**: WLS-108, WLS-135 (NextJS)

#### User Story

As a new studio owner
I want to create my account with secure authentication
So that I can access the platform and manage my studio

#### Use Cases

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

#### Acceptance Criteria

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

#### Phoenix/Elixir/Ash Implementation

**Domain**: Accounts

**Ash Resource with AshAuthentication**:
```elixir
# lib/pilates_on_phx/accounts/user.ex
defmodule PilatesOnPhx.Accounts.User do
  use Ash.Resource,
    domain: PilatesOnPhx.Accounts,
    extensions: [AshAuthentication]

  authentication do
    strategies do
      password :password do
        identity_field :email
        hashed_password_field :hashed_password

        register_action_accept [:email, :role]

        sign_in_action_name :sign_in_with_password
        registration_action_name :register_with_password
      end

      # OAuth providers
      oauth2 :google do
        client_id &get_config/2
        client_secret &get_config/2
        redirect_uri &get_config/2
      end
    end

    tokens do
      enabled? true
      token_resource PilatesOnPhx.Accounts.Token
    end
  end

  attributes do
    uuid_primary_key :id
    attribute :email, :ci_string, allow_nil?: false
    attribute :hashed_password, :string, allow_nil?: false, sensitive?: true
    attribute :role, :atom, constraints: [one_of: [:owner, :instructor, :client]]
    attribute :email_verified, :boolean, default: false
  end

  actions do
    create :register_owner do
      accept [:email, :hashed_password]
      change set_attribute(:role, :owner)
      change trigger_auto_create_org_studio()  # Calls database function
    end
  end
end
```

**Database Trigger** (PostgreSQL):
```sql
-- Migration: Auto-create Organization + Studio + Progress
CREATE OR REPLACE FUNCTION handle_new_owner_signup()
RETURNS TRIGGER AS $$
DECLARE
  new_org_id UUID;
  new_studio_id BIGINT;
BEGIN
  IF NEW.role = 'owner' THEN
    -- Create organization
    INSERT INTO organizations (name, created_at, updated_at)
    VALUES ('New Organization', NOW(), NOW())
    RETURNING id INTO new_org_id;

    -- Link user to organization
    UPDATE users SET organization_id = new_org_id WHERE id = NEW.id;

    -- Create studio
    INSERT INTO studios (name, organization_id, owner_id, created_at, updated_at)
    VALUES ('My Studio', new_org_id, NEW.id, NOW(), NOW())
    RETURNING id INTO new_studio_id;

    -- Create onboarding progress
    INSERT INTO studio_onboarding_progress (studio_id, current_step, created_at, updated_at)
    VALUES (new_studio_id, 1, NOW(), NOW());
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_new_owner_signup
AFTER INSERT ON users
FOR EACH ROW
EXECUTE FUNCTION handle_new_owner_signup();
```

**LiveView Component**:
```elixir
defmodule PilatesOnPhxWeb.Auth.RegisterLive do
  use PilatesOnPhxWeb, :live_view

  def handle_event("register", %{"user" => user_params}, socket) do
    case PilatesOnPhx.Accounts.User
         |> Ash.Changeset.for_create(:register_owner, user_params)
         |> Ash.create() do
      {:ok, user} ->
        # Send verification email
        send_verification_email(user)

        # Redirect to onboarding
        {:noreply, redirect(socket, to: "/onboarding")}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
```

#### Dependencies

- PHX-2: Accounts Domain (User, Organization, Token)
- PHX-3: Studios Domain (Studio, StudioOnboardingProgress)
- AshAuthentication package

#### Testing Strategy

- Test email/password registration
- Test OAuth registration (mock providers)
- Test password validation rules
- Test duplicate email handling
- Test database trigger (org/studio auto-creation)
- Test email verification flow
- Integration test for complete signup → onboarding
- 85%+ coverage

#### Definition of Done

- [ ] Email/password auth working
- [ ] OAuth providers integrated (Google)
- [ ] Database trigger functional
- [ ] Email verification implemented
- [ ] Tests passing
- [ ] Security audit complete
- [ ] Code reviewed
- [ ] Deployed to staging

---

### PHX-15: Business Model Selection (Step 3)

**Parent**: PHX-10
**Project**: Sprint 2 - Core User Workflows
**Priority**: Urgent (1)
**Labels**: onboarding, studios-domain, business-model, sprint-2

**Original Source**: WLS-101 (Business Model Section)

#### User Story

As a studio owner
I want to select my business model (Standard vs Contract Labor)
So that the platform configures appropriate features and reporting for my revenue model

#### Use Cases

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

#### Acceptance Criteria

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

#### Phoenix/Elixir/Ash Implementation

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

# Custom change for feature flags
defmodule SetFeatureFlagsForBusinessModel do
  use Ash.Resource.Change

  def change(changeset, _opts, _context) do
    case Ash.Changeset.get_attribute(changeset, :business_model) do
      :standard ->
        Ash.Changeset.change_attribute(changeset, :feature_flags, %{
          enable_class_bookings: true,
          enable_room_rentals: false,
          enable_package_sales: true,
          revenue_model: "class_bookings"
        })

      :contract_labor ->
        Ash.Changeset.change_attribute(changeset, :feature_flags, %{
          enable_class_bookings: false,
          enable_room_rentals: true,
          enable_instructor_payments: true,
          revenue_model: "room_rentals"
        })
    end
  end
end
```

**LiveView Component**:
```elixir
defmodule PilatesOnPhxWeb.Onboarding.BusinessModelLive do
  use PilatesOnPhxWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto">
      <.step_indicator current_step={3} total_steps={6} />

      <h1>Select Your Business Model</h1>
      <p>This determines how your studio tracks revenue and manages instructors.</p>

      <.form for={@form} phx-submit="continue">
        <.radio_card
          name="business_model"
          value="standard"
          checked={@selected == :standard}
          title="Standard Studio with Employees"
          description="Instructors are W-2 employees. Revenue from class bookings and package sales."
        />

        <.radio_card
          name="business_model"
          value="contract_labor"
          checked={@selected == :contract_labor}
          title="Contract Labor Renting Space"
          description="Instructors are 1099 contractors who rent your space. Revenue from room rental fees."
        />

        <.button type="submit">Continue to Studio Configuration</.button>
      </.form>
    </div>
    """
  end

  def handle_event("continue", %{"business_model" => model}, socket) do
    case update_studio_business_model(socket.assigns.studio, model) do
      {:ok, _studio} ->
        {:noreply, redirect(socket, to: "/onboarding/step4")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Please select a business model")}
    end
  end
end
```

#### Dependencies

- PHX-3: Studios Domain (Studio resource)
- PHX-13: Basic studio info must be complete

#### Testing Strategy

- Test standard model selection and feature flags
- Test contract labor model selection and flags
- Test validation (cannot skip)
- Test LiveView form submission
- Test reporting template configuration
- 85%+ coverage

#### Definition of Done

- [ ] Radio selection working
- [ ] Feature flags configured correctly
- [ ] Reporting templates set
- [ ] Validation prevents skipping
- [ ] Tests passing
- [ ] Can change later in settings
- [ ] Code reviewed
- [ ] Deployed

---

## Summary: Issues Created vs. Remaining

### ✅ Created in Linear

1. **Sprint 2 Project**: Sprint 2 - Core User Workflows
2. **PHX-10** (Epic): Studio Onboarding & Setup Wizard
3. **PHX-11** (Epic): Class Scheduling & Recurring Classes

### 📝 Ready to Create (Copy/Paste from this document)

**Epic**:
- PHX-12: Booking Workflow & Package Management

**Onboarding Stories** (Parent: PHX-10):
- PHX-13: Studio Basic Information Capture
- PHX-14: Owner Account Initial Setup
- PHX-15: Business Model Selection
- PHX-16: Studio Configuration Settings
- PHX-17: Class Types Setup
- PHX-18: Rooms & Facilities Management
- PHX-19: Equipment Inventory (Optional)

**Class Scheduling Stories** (Parent: PHX-11):
- PHX-20: Create Single Class Session
- PHX-21: Recurring Class Series Creation
- PHX-22: Edit Recurring Class Series
- PHX-23: Cancel/Delete Recurring Series
- PHX-24: Class Calendar View

**Booking Workflow Stories** (Parent: PHX-12):
- PHX-25: Client Registration & Profile
- PHX-26: Package Purchase with Stripe
- PHX-27: Browse Available Classes
- PHX-28: Book Class with Credits
- PHX-29: Join Waitlist When Full
- PHX-30: Cancel Booking
- PHX-31: Staff Batch Check-In
- PHX-32: Package Conversion Request
- PHX-33: Attendance Tracking

**Total**: 1 Epic + 21 User Stories = 22 issues

---

## Next Steps

1. Copy each issue's content above
2. Create in Linear using the web UI or API
3. Ensure proper parent epic assignment
4. Set project to "Sprint 2 - Core User Workflows"
5. Set appropriate priorities and labels
6. Once created, continue with Sprint 3 and 4 planning

The remaining user stories follow the same comprehensive template with:
- Original WLS source
- Complete Gherkin use cases
- Phoenix/Elixir/Ash implementation
- Testing strategies
- Dependencies

Would you like me to continue with the complete specifications for the remaining 18 user stories?
