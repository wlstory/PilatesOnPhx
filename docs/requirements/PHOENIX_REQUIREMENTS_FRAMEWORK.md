# Phoenix/Elixir/Ash Requirements Framework
## Comprehensive Mapping from NextJS/Rails to Phoenix

---

## PART 1: DOMAIN CATEGORIZATION FRAMEWORK

### 1. Authentication & Multi-Tenant
**NextJS Patterns → Phoenix/Ash Patterns**
- React Auth Context → AshAuthentication with token strategy
- Supabase RLS → Ash Policies with multi-tenant
- NextAuth.js → AshAuthentication.Phoenix
- JWT tokens → Ash tokens stored in database
- Organization context → tenant attribute in Ash resources

**Key Phoenix Issues to Create:**
- PHX-20: Multi-tenant authentication setup
- PHX-21: Organization context switching
- PHX-22: Role-based authorization policies
- PHX-23: User invitation workflow
- PHX-24: Password reset flow

---

### 2. Studio Management
**NextJS Patterns → Phoenix/Ash Patterns**
- React form components → Phoenix LiveView forms
- Server actions → Ash actions (create, update, delete)
- Optimistic updates → LiveView assigns + temporary assigns
- File uploads (logo, branding) → Phoenix uploads + storage

**Key Phoenix Issues to Create:**
- PHX-25: Studio onboarding wizard (6-step LiveView)
- PHX-26: Studio basic information form
- PHX-27: Studio settings and configuration
- PHX-28: Timezone and display preferences
- PHX-29: Branding and customization
- PHX-30: Multi-studio management for owners

**Sprint Assignment:** Sprint 2 (depends on PHX-1 Studio resource)

---

### 3. Class Management
**NextJS Patterns → Phoenix/Ash Patterns**
- Class scheduling UI → LiveView calendar component
- Recurring series logic → Ash actions with calculations
- React Calendar → LiveView hooks + JavaScript interop
- Drag-and-drop scheduling → Phoenix.LiveView.JS

**Key Phoenix Issues to Create:**
- PHX-31: Class type creation and management
- PHX-32: Single class scheduling
- PHX-33: Recurring class series creation
- PHX-34: Recurring series cancellation/modification
- PHX-35: Class capacity and room management
- PHX-36: Instructor assignment to classes
- PHX-37: Class template system

**Sprint Assignment:** Sprint 2-3 (depends on PHX-2 Class resource)

---

### 4. Client Management
**NextJS Patterns → Phoenix/Ash Patterns**
- Client profile forms → LiveView forms with Ash changesets
- Client search → Ash queries with filters
- Client dashboard → LiveView with streams

**Key Phoenix Issues to Create:**
- PHX-38: Client profile creation and editing
- PHX-39: Client search and filtering
- PHX-40: Client emergency contacts
- PHX-41: Client preferences and settings
- PHX-42: Client notes and history
- PHX-43: Client package ownership display

**Sprint Assignment:** Sprint 2 (depends on PHX-3 Client resource)

---

### 5. Package System
**NextJS Patterns → Phoenix/Ash Patterns**
- Package purchase flow → LiveView multi-step form
- Credit tracking → Ash calculations and aggregates
- Expiration logic → Oban scheduled jobs
- Package conversions → Ash actions with validations

**Key Phoenix Issues to Create:**
- PHX-44: Package type creation and management
- PHX-45: Package purchase workflow
- PHX-46: Package credit tracking and consumption
- PHX-47: Package expiration and renewal
- PHX-48: Package conversion request/approval
- PHX-49: Package transfer between clients
- PHX-50: Unlimited package handling

**Sprint Assignment:** Sprint 3 (depends on PHX-4 Package resource)

---

### 6. Booking System
**NextJS Patterns → Phoenix/Ash Patterns**
- Booking modal → LiveView modal component
- Real-time availability → PubSub + LiveView streams
- Waitlist management → Ash actions + Oban workers
- Booking rules → Ash validations and policies

**Key Phoenix Issues to Create:**
- PHX-51: Single class booking by client
- PHX-52: Single class booking by staff
- PHX-53: Recurring series booking
- PHX-54: Booking cancellation workflow
- PHX-55: Waitlist enrollment
- PHX-56: Waitlist promotion on cancellation
- PHX-57: Late cancellation policies
- PHX-58: Booking conflict detection

**Sprint Assignment:** Sprint 2 (depends on PHX-5 Booking resource)

---

### 7. Attendance & Check-In
**NextJS Patterns → Phoenix/Ash Patterns**
- Check-in interface → LiveView with real-time updates
- Barcode scanning → Phoenix LiveView hooks + JS
- Bulk check-in → Ash bulk actions
- No-show tracking → Ash calculations

**Key Phoenix Issues to Create:**
- PHX-59: Manual check-in by staff
- PHX-60: Self-check-in kiosk mode
- PHX-61: Bulk check-in interface
- PHX-62: No-show marking and penalties
- PHX-63: Attendance history and reports
- PHX-64: Late arrival handling

**Sprint Assignment:** Sprint 3 (depends on booking system)

---

### 8. Payments & Billing
**NextJS Patterns → Phoenix/Ash Patterns**
- Stripe integration → Phoenix webhooks + Oban
- Payment forms → LiveView + Stripe Elements
- Invoice generation → Ash calculations + PDF generation
- Refund processing → Ash actions with validations

**Key Phoenix Issues to Create:**
- PHX-65: Stripe account connection
- PHX-66: Payment method management
- PHX-67: Package purchase payment flow
- PHX-68: Invoice generation and viewing
- PHX-69: Refund processing
- PHX-70: Payment history and receipts
- PHX-71: Failed payment handling
- PHX-72: Webhook processing for Stripe events

**Sprint Assignment:** Sprint 4 (depends on package system)

---

### 9. Communications
**NextJS Patterns → Phoenix/Ash Patterns**
- Email templates → Phoenix.Swoosh + EEx templates
- SMS notifications → Twilio integration + Oban
- Push notifications → Phoenix PubSub + web push
- Scheduled reminders → Oban cron jobs

**Key Phoenix Issues to Create:**
- PHX-73: Email template system
- PHX-74: Booking confirmation emails
- PHX-75: Class reminder emails (24h, 1h before)
- PHX-76: SMS notification integration
- PHX-77: Push notification system
- PHX-78: Waitlist promotion notifications
- PHX-79: Cancellation notification workflow
- PHX-80: Newsletter and announcement system

**Sprint Assignment:** Sprint 3-4 (depends on Oban setup)

---

### 10. Reporting & Analytics
**NextJS Patterns → Phoenix/Ash Patterns**
- Report generation → Ash aggregates + LiveView
- Scheduled reports → Oban workers
- CSV export → Ash queries + CSV library
- Dashboard charts → LiveView + Chart.js

**Key Phoenix Issues to Create:**
- PHX-81: Attendance reports
- PHX-82: Revenue reports
- PHX-83: Client activity reports
- PHX-84: Class utilization reports
- PHX-85: Package sales reports
- PHX-86: Scheduled report delivery
- PHX-87: Custom report builder
- PHX-88: Report export (PDF, CSV, Excel)

**Sprint Assignment:** Sprint 4 (depends on data models)

---

### 11. Automation & Background Jobs
**NextJS Patterns → Phoenix/Ash Patterns**
- pg-boss/cron → Oban workers and cron
- Server actions → Ash actions
- Background tasks → Oban jobs
- Scheduled tasks → Oban.Cron

**Key Phoenix Issues to Create:**
- PHX-89: Package expiration checker (daily)
- PHX-90: Class reminder sender (hourly)
- PHX-91: Waitlist processor (on cancellation)
- PHX-92: Report generator scheduler
- PHX-93: Data cleanup jobs
- PHX-94: Audit log archival
- PHX-95: Failed payment retry logic

**Sprint Assignment:** Sprint 3 (depends on Oban configuration)

---

### 12. Mobile/PWA Features
**NextJS Patterns → Phoenix/Ash Patterns**
- PWA manifest → Phoenix static assets
- Service worker → Custom JS service worker
- Offline support → IndexedDB + sync
- Mobile navigation → LiveView mobile-first UI

**Key Phoenix Issues to Create:**
- PHX-96: PWA manifest and service worker
- PHX-97: Offline booking queue
- PHX-98: Mobile-optimized navigation
- PHX-99: Push notification permissions
- PHX-100: Mobile check-in interface
- PHX-101: Native app shell (optional)

**Sprint Assignment:** Sprint 5 (nice-to-have)

---

### 13. Admin Tools & Data Management
**NextJS Patterns → Phoenix/Ash Patterns**
- Admin dashboard → AshAdmin interface
- Data imports → CSV parsing + Ash bulk creates
- Data exports → Ash queries + export formats
- System settings → Ash resources with policies

**Key Phoenix Issues to Create:**
- PHX-102: AshAdmin interface configuration
- PHX-103: Data import wizard (clients, classes)
- PHX-104: Data export interface
- PHX-105: System health monitoring
- PHX-106: Audit log viewer
- PHX-107: User management interface
- PHX-108: Studio migration tools
- PHX-109: Bulk data operations

**Sprint Assignment:** Sprint 4-5 (admin tooling)

---

## PART 2: SPRINT 1 COVERAGE ANALYSIS

### Sprint 1 Issues (PHX-1 to PHX-8)
From the context, Sprint 1 covered foundational resources:
- PHX-1: Studio resource (Ash)
- PHX-2: Class resource (Ash)
- PHX-3: Client resource (Ash)
- PHX-4: Package resource (Ash)
- PHX-5: Booking resource (Ash)
- PHX-6: User authentication (AshAuthentication)
- PHX-7: Multi-tenant setup (Ash Policies)
- PHX-8: Basic LiveView scaffolding

### What Sprint 1 DOES NOT Cover
- **Studio onboarding wizard** (multi-step UI)
- **Recurring class series** (complex logic)
- **Package conversions** (approval workflow)
- **Scheduled reports** (Oban cron)
- **Staff workflows** (check-in, cancellation)
- **Real-time updates** (PubSub)
- **Payment integration** (Stripe)
- **Communications** (email, SMS)
- **Mobile/PWA** (offline, push)
- **Admin tools** (data import/export)

---

## PART 3: ISSUE CREATION TEMPLATE

### Template for Each PHX Issue

```markdown
# PHX-XXX: [Feature Title]

## Original Requirement
**Reference:** WLS-XXX or RAILS-XXX
**Original Team:** Wlstory (NextJS) / AltBuild-Rails

## User Story
As a [role/persona from Catalio.Documentation.Persona],
I can [activity],
so that [business benefit].

**Personas Involved:**
- Studio Owner
- Instructor
- Client
- Staff Member

## Use Cases

### Scenario: [Happy Path] Primary Success Flow
Given [initial state]
When [user action]
Then [expected outcome]
And [side effects or additional validation]

### Scenario: [Edge Case] Alternative Flow
Given [alternative state]
When [different action]
Then [alternative outcome]

### Scenario: [Error Case] Error Handling
Given [error condition]
When [action that triggers error]
Then [error handled gracefully]
And [appropriate error message displayed]

## Acceptance Criteria
1. [Testable criterion derived from use cases]
2. [User interface requirement]
3. [Business logic validation]
4. [Authorization check]
5. [Performance requirement]
6. [Accessibility requirement]

## Technical Implementation Details

### Reusable Modules/Resources
- **Ash Resources:** PilatesOnPhx.Studios.Studio, PilatesOnPhx.Classes.Class
- **Ash Domains:** PilatesOnPhx.Studios, PilatesOnPhx.Classes
- **LiveView Components:** PilatesOnPhxWeb.CoreComponents
- **Authentication:** AshAuthentication with token strategy

### Implementation Patterns
- **LiveView Pattern:** [Specific pattern from AGENTS.md lines XXX-YYY]
- **Ash Action Pattern:** [Action type with validations from AGENTS.md lines XXX-YYY]
- **Multi-tenant Pattern:** [tenant attribute usage from CLAUDE.md lines XXX-YYY]
- **Form Pattern:** [Phoenix.Component.form with Ash changeset]

### Dependencies
- **Ash Resources:** Requires PHX-1 (Studio), PHX-2 (Class)
- **Authentication:** Requires PHX-6 (User auth), PHX-7 (Multi-tenant)
- **External Services:** Stripe API, Twilio API (if applicable)
- **Database:** Requires migrations for [specific tables/columns]

### Code Organization
- **Resource Location:** lib/pilates_on_phx/[domain]/[resource].ex
- **LiveView Location:** lib/pilates_on_phx_web/live/[domain]/[feature]_live.ex
- **Components:** lib/pilates_on_phx_web/components/[domain]_components.ex
- **Ash Actions:** Define in resource using `actions do ... end`

### Security Considerations
- **Authorization:** Ash policy checks for [specific roles]
- **Multi-tenant Isolation:** Ensure `tenant: :organization` attribute filtering
- **Rate Limiting:** Apply rate limits for [specific actions]
- **Input Validation:** Validate [specific fields] using Ash validations
- **CSRF Protection:** LiveView provides built-in CSRF protection

### Performance Considerations
- **Query Optimization:** Use Ash preloads for [relationships]
- **Caching Strategy:** Cache [specific data] using Cachex or ETS
- **Bulk Operations:** Use Ash.bulk_create for [batch operations]
- **Database Indexes:** Add indexes on [specific columns]
- **N+1 Prevention:** Preload relationships in Ash queries

### Testing Strategy
- **Business Logic Tests:** Test Ash actions with real database (AGENTS.md)
- **Authorization Tests:** Verify policies with different actors
- **LiveView Tests:** Use Phoenix.LiveViewTest for UI interactions
- **Integration Tests:** Test complete workflows end-to-end
- **Edge Cases:** Test boundary conditions and error scenarios
- **Coverage Target:** 85%+ focusing on PilatesOnPhx business logic

## Supporting Documentation
- **AGENTS.md Lines XXX-YYY:** [Specific pattern or guideline]
- **CLAUDE.md Lines XXX-YYY:** [Project-specific convention]
- **Data Model:** docs/technical/data-model.md (if exists)
- **Related Resources:** [List similar implementations]

## References
- **Original Issue:** [Linear URL to WLS-XXX or RAILS-XXX]
- **Code Files:**
  - `/Users/wlstory/src/PilatesOnPhx/lib/pilates_on_phx/[domain]/[resource].ex`
  - `/Users/wlstory/src/PilatesOnPhx/lib/pilates_on_phx_web/live/[feature]_live.ex`
- **Related PHX Issues:** PHX-1, PHX-2, PHX-3 (dependencies)

## Labels
- `feature` (or `enhancement`, `bug`)
- `sprint-2` (or `sprint-3`, `sprint-4`, `sprint-5`)
- `domain:[domain-name]` (e.g., `domain:studio`, `domain:booking`)
- `priority:high` (or `priority:medium`, `priority:low`)

## Priority
- **Priority Level:** High / Medium / Low
- **Business Impact:** [Explanation of business value]
- **Technical Risk:** [Any technical challenges or unknowns]

## Project
- **Project:** "Foundational Setup🚀" or "Phoenix Migration"

## Milestone
- **Milestone:** "Sprint 2: Core Workflows" (or Sprint 3/4/5)

## Dependencies
- **Blocked By:** PHX-1 (Studio resource), PHX-6 (Authentication)
- **Blocks:** PHX-YYY (future feature)
- **Related To:** PHX-ZZZ (similar feature)
```

---

## PART 4: SPRINT ASSIGNMENT CRITERIA

### Sprint 2: Core User Workflows (High Priority)
**Focus:** Essential features users need immediately after Sprint 1 foundation

**Criteria for Sprint 2:**
- Directly uses Sprint 1 resources (Studio, Class, Client, Booking, Package)
- High business value for daily operations
- Required for MVP launch
- User-facing workflows (not admin tools)
- No complex integrations

**Typical Sprint 2 Features:**
- Studio onboarding wizard
- Class scheduling (single and recurring)
- Client booking workflow
- Staff check-in interface
- Basic studio settings

### Sprint 3: Automation & Background Jobs (Medium Priority)
**Focus:** Automation, scheduled tasks, and enhanced workflows

**Criteria for Sprint 3:**
- Requires Oban setup and configuration
- Background processing needs
- Scheduled tasks (cron jobs)
- Email/SMS notifications
- Report generation

**Typical Sprint 3 Features:**
- Scheduled reminders
- Package expiration automation
- Waitlist promotion automation
- Email notification system
- Basic reporting

### Sprint 4: Integrations & Advanced Features (Medium-Low Priority)
**Focus:** Third-party integrations and advanced functionality

**Criteria for Sprint 4:**
- Requires external service integration
- Payment processing (Stripe)
- Advanced reporting and analytics
- Admin tools and data management
- Non-critical enhancements

**Typical Sprint 4 Features:**
- Stripe payment integration
- Advanced reporting dashboard
- Data import/export tools
- Invoice generation
- System health monitoring

### Sprint 5+: Nice-to-Have Features (Low Priority)
**Focus:** Polish, mobile optimization, and future enhancements

**Criteria for Sprint 5:**
- Mobile/PWA specific features
- Offline functionality
- Advanced UI/UX improvements
- Performance optimizations
- Experimental features

**Typical Sprint 5 Features:**
- PWA offline support
- Native mobile app features
- Advanced analytics
- Custom branding tools
- AI/ML features

---

## PART 5: PHOENIX/ELIXIR/ASH PATTERN MAPPING

### NextJS Server Actions → Ash Actions
```elixir
# NextJS Server Action
async function createClass(formData) {
  const result = await db.class.create({ data: formData })
  revalidatePath('/classes')
  return result
}

# Phoenix/Ash Equivalent
def create_class(attrs, actor) do
  Class
  |> Ash.Changeset.for_create(:create, attrs, actor: actor)
  |> Ash.create()
end

# In LiveView
def handle_event("create_class", params, socket) do
  case create_class(params, socket.assigns.current_user) do
    {:ok, class} ->
      {:noreply, push_navigate(socket, to: ~p"/classes")}
    {:error, changeset} ->
      {:noreply, assign(socket, changeset: changeset)}
  end
end
```

### React State Management → LiveView Assigns
```elixir
# React useState
const [classes, setClasses] = useState([])
const [loading, setLoading] = useState(true)

# Phoenix LiveView
def mount(_params, _session, socket) do
  {:ok,
   socket
   |> assign(:classes, [])
   |> assign(:loading, true)
   |> load_classes()}
end

defp load_classes(socket) do
  classes = Class |> Ash.read!(actor: socket.assigns.current_user)
  
  socket
  |> assign(:classes, classes)
  |> assign(:loading, false)
end
```

### REST API Endpoints → Ash Actions Exposed via LiveView
```elixir
# NextJS API Route
export async function GET(request) {
  const classes = await db.class.findMany()
  return Response.json(classes)
}

# Phoenix LiveView (no API needed)
def render(assigns) do
  ~H"""
  <div :for={class <- @classes}>
    <%= class.name %>
  </div>
  """
end

# Or if API needed: AshJsonApi
json_api do
  type "class"
  routes do
    base "/classes"
    get :read
    post :create
  end
end
```

### Background Jobs (pg-boss) → Oban Workers
```elixir
# NextJS pg-boss
await boss.send('send-reminder', { classId: 123 })

# Phoenix Oban
defmodule PilatesOnPhx.Workers.SendReminder do
  use Oban.Worker, queue: :notifications

  @impl Oban.Worker
  def perform(%Job{args: %{"class_id" => class_id}}) do
    # Send reminder logic
    :ok
  end
end

# Enqueue job
%{class_id: 123}
|> SendReminder.new()
|> Oban.insert()
```

### Webhooks (Stripe) → Phoenix Channels/Controllers
```elixir
# NextJS Webhook Handler
export async function POST(request) {
  const event = await stripe.webhooks.constructEvent(...)
  // Handle event
}

# Phoenix Webhook Controller
defmodule PilatesOnPhxWeb.StripeWebhookController do
  use PilatesOnPhxWeb, :controller

  def create(conn, params) do
    case Stripe.Webhook.construct_event(...) do
      {:ok, event} -> handle_event(event)
      {:error, _} -> conn |> put_status(400) |> json(%{error: "Invalid signature"})
    end
  end
end
```

### Supabase RLS Policies → Ash Policies
```elixir
# Supabase RLS
CREATE POLICY "Users can only see their org's studios"
ON studios FOR SELECT
USING (organization_id = auth.uid());

# Ash Policy
policies do
  policy action_type(:read) do
    authorize_if relates_to_actor_via(:organization)
  end
end

# In resource
multitenancy do
  strategy :attribute
  attribute :organization_id
  parse_attribute {PilatesOnPhx.Multitenancy, :get_organization_id, []}
end
```

---

## PART 6: COMPREHENSIVE ISSUE MAPPING GUIDE

### For Each NextJS/Rails Issue, Ask:

1. **What business value does this provide?**
   - Map to user story with persona

2. **What technical pattern does it use?**
   - React component → LiveView component
   - Server action → Ash action
   - Background job → Oban worker
   - Database query → Ash query
   - API endpoint → Ash action (or AshJsonApi if needed)

3. **What Sprint 1 resources does it depend on?**
   - Check PHX-1 through PHX-8 dependencies

4. **What new resources or actions are needed?**
   - Identify gaps in current Ash resources

5. **What authorization rules apply?**
   - Map to Ash policies

6. **What integrations are required?**
   - Stripe, Twilio, email services, etc.

7. **What background jobs are needed?**
   - Map to Oban workers

8. **What real-time features are needed?**
   - Map to PubSub + LiveView updates

9. **What performance considerations exist?**
   - Caching, preloading, bulk operations

10. **What testing approach is required?**
    - Business logic tests (85%+ coverage)
    - LiveView interaction tests
    - Authorization tests
    - Integration tests

---

## PART 7: EXAMPLE ISSUE CREATION

### Example 1: Studio Onboarding Wizard

**Original:** WLS-101 (NextJS)

**PHX Issue:**

```markdown
# PHX-25: Studio Onboarding Wizard (6-Step Process)

## Original Requirement
**Reference:** WLS-101
**Original Team:** Wlstory (NextJS)
**Original Description:** 6-step wizard for new studio owners to set up their studio, configure settings, add rooms, create class types, invite instructors, and configure billing.

## User Story
As a studio owner (Catalio.Documentation.Persona: :studio_owner),
I can complete a guided 6-step onboarding wizard,
so that I can quickly set up my studio and start accepting bookings without needing technical expertise.

**Personas Involved:**
- Studio Owner (primary actor)

## Use Cases

### Scenario: [Happy Path] Complete Studio Onboarding
Given I am a new studio owner who just created an account
When I navigate to the onboarding wizard
Then I see Step 1: Studio Basic Information form
When I fill in studio name, address, phone, and email
And I click "Next"
Then I see Step 2: Studio Settings form
When I configure timezone, booking policies, and display preferences
And I click "Next"
Then I see Step 3: Rooms & Facilities setup
When I add at least one room with capacity
And I click "Next"
Then I see Step 4: Class Types creation
When I add at least one class type with duration and default price
And I click "Next"
Then I see Step 5: Invite Instructors
When I optionally add instructor emails (can skip)
And I click "Next"
Then I see Step 6: Billing Setup
When I connect my Stripe account or skip for later
And I click "Complete Setup"
Then I am redirected to the studio dashboard
And I see a success message "Your studio is ready!"
And invitation emails are sent to instructors (if any were added)

### Scenario: [Edge Case] Save Progress and Return Later
Given I am in the middle of the onboarding wizard (Step 3)
When I navigate away or close the browser
And I return to the application later
Then I am automatically returned to Step 3 where I left off
And all previously entered data is preserved

### Scenario: [Edge Case] Skip Optional Steps
Given I am on Step 5: Invite Instructors
When I click "Skip" without adding any instructors
Then I proceed to Step 6: Billing Setup
And I can still invite instructors later from settings

### Scenario: [Error Case] Invalid Studio Information
Given I am on Step 1: Studio Basic Information
When I submit the form with an invalid email address
Then I see an error message "Please enter a valid email address"
And I remain on Step 1
And all valid fields retain their values

### Scenario: [Error Case] No Rooms Added
Given I am on Step 3: Rooms & Facilities
When I click "Next" without adding any rooms
Then I see an error message "Please add at least one room to continue"
And I cannot proceed to Step 4

## Acceptance Criteria
1. **Wizard Navigation:**
   - User can navigate forward through steps by clicking "Next"
   - User can navigate backward through steps by clicking "Back"
   - Current step is visually indicated (progress bar or step indicator)
   - User cannot skip required steps (Steps 1-4)
   - User can skip optional steps (Steps 5-6)

2. **Data Persistence:**
   - Data entered in each step is saved automatically
   - User can close browser and resume at the same step
   - User can edit previous steps by clicking "Back"

3. **Form Validation:**
   - Each step validates required fields before allowing "Next"
   - Clear error messages are displayed for invalid inputs
   - Valid inputs are retained when navigating between steps

4. **Required vs Optional Steps:**
   - Steps 1-4 are required (cannot complete without them)
   - Steps 5-6 are optional (can be skipped)
   - Clear indication of which steps are optional

5. **Completion:**
   - Upon completion, user is redirected to studio dashboard
   - Success message is displayed
   - Studio status is marked as "onboarded"
   - Invitation emails are sent to any invited instructors

6. **Accessibility:**
   - Keyboard navigation works for all steps
   - Screen readers announce current step and progress
   - Focus management when navigating between steps

## Technical Implementation Details

### Reusable Modules/Resources
- **Ash Resources:**
  - PilatesOnPhx.Studios.Studio (PHX-1)
  - PilatesOnPhx.Studios.Room (new resource needed)
  - PilatesOnPhx.Classes.ClassType (new resource needed)
  - PilatesOnPhx.Accounts.User (PHX-6)
- **Ash Domains:**
  - PilatesOnPhx.Studios
  - PilatesOnPhx.Classes
  - PilatesOnPhx.Accounts
- **LiveView Components:**
  - PilatesOnPhxWeb.CoreComponents (form, button, input)
  - New: OnboardingComponents (step_indicator, progress_bar)

### Implementation Patterns
- **LiveView Pattern:** Multi-step form with live validation (AGENTS.md lines 500-600)
- **Ash Action Pattern:** Update actions for each step with specific validations
- **State Management:** LiveView assigns to track current_step, form_data, errors
- **Form Pattern:** Phoenix.Component.form with Ash changeset per step

```elixir
# LiveView module structure
defmodule PilatesOnPhxWeb.OnboardingLive do
  use PilatesOnPhxWeb, :live_view
  require Ash.Query

  def mount(_params, _session, socket) do
    studio = get_or_create_studio(socket.assigns.current_user)
    
    {:ok,
     socket
     |> assign(:studio, studio)
     |> assign(:current_step, determine_current_step(studio))
     |> assign_step_form()}
  end

  def handle_event("next_step", params, socket) do
    case save_current_step(socket, params) do
      {:ok, studio} ->
        next_step = socket.assigns.current_step + 1
        {:noreply,
         socket
         |> assign(:studio, studio)
         |> assign(:current_step, next_step)
         |> assign_step_form()}
      
      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("previous_step", _params, socket) do
    prev_step = max(1, socket.assigns.current_step - 1)
    {:noreply,
     socket
     |> assign(:current_step, prev_step)
     |> assign_step_form()}
  end

  defp save_current_step(socket, params) do
    action = step_action(socket.assigns.current_step)
    
    socket.assigns.studio
    |> Ash.Changeset.for_update(action, params, actor: socket.assigns.current_user)
    |> Ash.update()
  end

  defp step_action(1), do: :update_basic_info
  defp step_action(2), do: :update_settings
  defp step_action(3), do: :update_rooms
  defp step_action(4), do: :update_class_types
  defp step_action(5), do: :invite_instructors
  defp step_action(6), do: :setup_billing
end
```

### Dependencies
- **Ash Resources:** PHX-1 (Studio), PHX-6 (User auth), PHX-7 (Multi-tenant)
- **New Resources Needed:**
  - Room resource (belongs_to Studio)
  - ClassType resource (belongs_to Studio)
- **External Services:** Stripe Connect (for Step 6)
- **Database Migrations:**
  - Add `onboarding_completed_at` timestamp to studios table
  - Add `onboarding_step` integer to studios table

### Code Organization
- **LiveView:** lib/pilates_on_phx_web/live/onboarding_live.ex
- **Components:** lib/pilates_on_phx_web/components/onboarding_components.ex
- **Ash Actions:** Add to lib/pilates_on_phx/studios/studio.ex
  - update_basic_info
  - update_settings
  - update_rooms
  - update_class_types
  - invite_instructors
  - setup_billing
  - complete_onboarding

### Security Considerations
- **Authorization:** Only studio owner can access onboarding for their studio
- **Multi-tenant Isolation:** Ensure studio belongs to current user's organization
- **Stripe Security:** Use Stripe Connect OAuth flow, never store API keys
- **Email Validation:** Validate instructor emails before sending invitations

```elixir
# In Studio resource
policies do
  policy action(:update_basic_info) do
    authorize_if actor_attribute_equals(:id, :owner_id)
  end
  
  policy action(:update_settings) do
    authorize_if actor_attribute_equals(:id, :owner_id)
  end
  
  # ... similar for other onboarding actions
end
```

### Performance Considerations
- **Preload Relationships:** Preload rooms, class_types when loading studio
- **Caching:** Cache studio data in LiveView assigns, don't refetch on each step
- **Lazy Loading:** Load Stripe account info only on Step 6
- **Database Indexes:** Add index on studios.owner_id for quick lookups

### Testing Strategy
- **Business Logic Tests:**
  - Test each Ash action (update_basic_info, etc.) with valid/invalid data
  - Test that onboarding_completed_at is set only after Step 6
  - Test that all required fields are validated at each step
  
- **Authorization Tests:**
  - Test that only studio owner can update their studio
  - Test that users cannot update other studios
  
- **LiveView Tests:**
  - Test navigation between steps (next/back buttons)
  - Test form validation on each step
  - Test progress persistence across page reloads
  - Test completion redirects to dashboard
  
- **Integration Tests:**
  - Test complete onboarding flow from Step 1 to Step 6
  - Test skipping optional steps
  - Test returning to incomplete onboarding
  
- **Edge Cases:**
  - Test concurrent updates (multiple browser tabs)
  - Test very long studio names (boundary testing)
  - Test invalid email formats for instructor invitations

**Coverage Target:** 90%+ (high-value user workflow)

## Supporting Documentation
- **AGENTS.md Lines 500-600:** LiveView multi-step form patterns
- **AGENTS.md Lines 1200-1300:** Ash action patterns with validations
- **CLAUDE.md Lines 100-150:** Multi-tenant architecture
- **Stripe Connect Docs:** OAuth flow for connected accounts

## References
- **Original Issue:** [Linear URL to WLS-101]
- **Code Files:**
  - `/Users/wlstory/src/PilatesOnPhx/lib/pilates_on_phx/studios/studio.ex`
  - `/Users/wlstory/src/PilatesOnPhx/lib/pilates_on_phx_web/live/onboarding_live.ex`
  - `/Users/wlstory/src/PilatesOnPhx/lib/pilates_on_phx_web/components/onboarding_components.ex`
- **Related PHX Issues:**
  - PHX-1 (Studio resource) - dependency
  - PHX-6 (User auth) - dependency
  - PHX-26 (Studio basic info form) - similar pattern
  - PHX-29 (Branding customization) - future enhancement

## Labels
- `feature`
- `sprint-2`
- `domain:studio`
- `priority:high`
- `onboarding`

## Priority
- **Priority Level:** High
- **Business Impact:** Critical for new studio owners to get started quickly. Reduces onboarding friction and support requests.
- **Technical Risk:** Medium (multi-step form complexity, Stripe integration)

## Project
- **Project:** "Foundational Setup🚀"

## Milestone
- **Milestone:** "Sprint 2: Core Workflows"

## Dependencies
- **Blocked By:**
  - PHX-1 (Studio resource)
  - PHX-6 (User authentication)
  - PHX-7 (Multi-tenant setup)
- **Blocks:**
  - PHX-26 (Studio settings can reuse onboarding forms)
  - PHX-29 (Branding customization)
- **Related To:**
  - PHX-27 (Studio settings page)
  - PHX-28 (Timezone preferences)
```

---

## PART 8: BATCH CREATION STRATEGY

Given the potential for 100+ issues, here's a recommended batch creation approach:

### Batch 1: Critical Sprint 2 Features (10-15 issues)
- Studio onboarding wizard
- Class scheduling (single + recurring)
- Client booking workflow
- Staff check-in interface
- Basic settings pages

### Batch 2: Extended Sprint 2 Features (10-15 issues)
- Package purchase workflow
- Waitlist management
- Booking cancellation
- Client profile management
- Class type management

### Batch 3: Sprint 3 Automation (10-15 issues)
- Oban workers for reminders
- Email notification system
- Package expiration automation
- Scheduled reports
- Background job processing

### Batch 4: Sprint 3 Communications (10-15 issues)
- Email templates
- SMS integration
- Push notifications
- Notification preferences
- Communication history

### Batch 5: Sprint 4 Payments (10-15 issues)
- Stripe integration
- Payment processing
- Invoice generation
- Refund handling
- Payment history

### Batch 6: Sprint 4 Reporting (10-15 issues)
- Attendance reports
- Revenue reports
- Analytics dashboard
- Export functionality
- Scheduled report delivery

### Batch 7: Sprint 4-5 Admin Tools (10-15 issues)
- Data import/export
- AshAdmin configuration
- System monitoring
- Audit logs
- Bulk operations

### Batch 8: Sprint 5 Mobile/PWA (5-10 issues)
- PWA manifest
- Offline support
- Mobile optimization
- Push permissions
- Native features

---

## PART 9: COVERAGE ANALYSIS FRAMEWORK

### How to Measure Coverage

For each NextJS/Rails feature:

1. **Categorize:** Which of the 13 domains?
2. **Sprint 1 Check:** Is it already covered by PHX-1 through PHX-8?
3. **Phoenix Mapping:** What's the equivalent Phoenix/Ash implementation?
4. **Priority:** High/Medium/Low based on business value?
5. **Dependencies:** What Sprint 1 issues does it depend on?
6. **Sprint Assignment:** 2, 3, 4, or 5?

### Coverage Report Template

```markdown
# Phoenix Requirements Coverage Report

## Summary Statistics
- **Total NextJS Issues Extracted:** XXX
- **Total Rails Issues Extracted:** YYY
- **Total Phoenix Issues Created:** ZZZ
- **Coverage Percentage:** (ZZZ / (XXX + YYY)) * 100%

## Coverage by Domain

### 1. Authentication & Multi-Tenant
- NextJS Features: XX
- Rails Features: YY
- Phoenix Issues: ZZ
- Coverage: ZZ%

### 2. Studio Management
- NextJS Features: XX
- Rails Features: YY
- Phoenix Issues: ZZ
- Coverage: ZZ%

[... repeat for all 13 domains]

## Coverage by Sprint

### Sprint 1 (Complete)
- Issues: PHX-1 through PHX-8
- Coverage: Foundational resources

### Sprint 2 (Planned)
- Issues: PHX-20 through PHX-45
- Coverage: Core user workflows
- Features: XX% of NextJS requirements

### Sprint 3 (Planned)
- Issues: PHX-46 through PHX-75
- Coverage: Automation and jobs
- Features: XX% of NextJS requirements

### Sprint 4 (Planned)
- Issues: PHX-76 through PHX-100
- Coverage: Integrations and advanced
- Features: XX% of NextJS requirements

### Sprint 5+ (Future)
- Issues: PHX-101+
- Coverage: Nice-to-have features
- Features: XX% of NextJS requirements

## Gap Analysis

### Features in NextJS/Rails NOT Yet Covered
1. [Feature Name] - WLS-XXX
   - **Reason:** [Why not covered yet]
   - **Recommendation:** [When to add or if needed]

2. [Feature Name] - RAILS-YYY
   - **Reason:** [Why not covered yet]
   - **Recommendation:** [When to add or if needed]

### Features Unique to Phoenix (Not in NextJS/Rails)
1. [Phoenix-specific advantage]
2. [Phoenix-specific advantage]

## Recommendations

### Immediate Actions (Sprint 2)
1. [High-priority feature to implement]
2. [High-priority feature to implement]

### Medium-Term (Sprint 3-4)
1. [Medium-priority feature]
2. [Medium-priority feature]

### Long-Term (Sprint 5+)
1. [Nice-to-have feature]
2. [Nice-to-have feature]

### Features to Potentially Skip
1. [Feature that may not be needed]
   - **Reason:** [Why it might not be valuable]
```

---

## EXECUTION RECOMMENDATION

Given the scope of this task (potentially 100+ issues to extract and create), I recommend the following approach:

### Option 1: Automated Extraction with Manual Review
1. **Use Linear API directly** to fetch all issues programmatically
2. **Parse and categorize** automatically using the 13-domain framework
3. **Generate Phoenix issue drafts** using the template
4. **Manual review** before creating in Linear
5. **Batch create** issues in groups of 20-30

### Option 2: Incremental Manual Process
1. **Start with Sprint 2 priorities** (fetch high-priority issues first)
2. **Create 10-15 issues** for critical features
3. **Get feedback** on structure and approach
4. **Iterate** on remaining batches
5. **Adjust** as needed based on learnings

### Option 3: Hybrid Approach (RECOMMENDED)
1. **Fetch all issues** from NextJS and Rails teams using Linear API
2. **Generate CSV or spreadsheet** with all requirements categorized
3. **Review and prioritize** with stakeholders
4. **Create issues incrementally** starting with Sprint 2
5. **Use automation** for bulk creation where appropriate

---

Would you like me to:

1. **Provide scripts** to fetch all Linear issues via API?
2. **Create a detailed spreadsheet template** for categorization?
3. **Start creating actual Phoenix issues** using the template (beginning with Sprint 2 priorities)?
4. **Generate a comprehensive mapping** of specific NextJS/Rails patterns to Phoenix/Ash equivalents?

Let me know which approach you prefer, and I'll proceed accordingly!
