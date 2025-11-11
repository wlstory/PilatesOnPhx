# PilatesOnPhx - Sprints 2, 3, 4 Feature Roadmap

**Project**: PilatesOnPhx Phoenix/Elixir/Ash Rewrite  
**Team**: AltBuild-PHX  
**Sprint 1 Status**: Complete (PHX-1 through PHX-8 - Ash Domain Architecture)  
**Created**: 2025-11-10

## Executive Summary

This roadmap defines features for Sprints 2, 3, and 4 of the PilatesOnPhx rewrite, building upon the Ash Domain Architecture foundation established in Sprint 1. Each sprint focuses on delivering production-ready functionality leveraging Phoenix LiveView, Oban background jobs, and Ash Framework's declarative patterns.

### Technology Advantages

**Phoenix LiveView**: Real-time UI updates without JavaScript complexity  
**Oban + AshOban**: Reliable background job processing with domain awareness  
**Ash Framework**: Declarative actions, calculations, aggregates, and authorization policies  
**Phoenix PubSub**: Real-time broadcasts across connected clients  

---

## SPRINT 2: LiveView Interfaces & User Workflows

**Goal**: Deliver client-facing and staff-facing real-time interfaces for core booking and management workflows.

**Duration**: 2-3 weeks  
**Dependencies**: Sprint 1 (PHX-1 through PHX-8)  
**Priority**: High

---

### PHX-9: Class Browse & Search Interface

**Title**: Implement LiveView class browse and search with real-time availability

**User Story**:  
As a client, I can browse and search available Pilates classes with real-time availability updates, so that I can quickly find and book classes that fit my schedule.

**Description**:  
Create a responsive, real-time class browsing interface using Phoenix LiveView streams. Clients can filter by date, time, instructor, class type, and studio location. Availability updates automatically via PubSub when bookings are made or cancelled.

**Use Cases**:

```gherkin
Scenario: [Happy Path] Browse today's classes with real-time availability
  Given I am a logged-in client
  When I navigate to the class browse page
  Then I see all classes scheduled for today
  And each class shows current available spots
  And classes are grouped by time slot
  And I see class type, instructor name, and studio location
  And availability updates in real-time when other clients book

Scenario: [Happy Path] Filter classes by instructor
  Given I am on the class browse page
  When I select "Sarah Johnson" from the instructor filter
  Then I see only classes taught by Sarah Johnson
  And the results update immediately without page reload
  And I can clear the filter to see all classes again

Scenario: [Happy Path] Filter classes by date range
  Given I am on the class browse page
  When I select "Next 7 Days" from the date filter
  Then I see all classes scheduled within the next week
  And classes are organized by date with headers
  And I can navigate to specific dates using a date picker

Scenario: [Edge Case] View full classes with waitlist
  Given I am browsing classes
  When a class has 0 available spots
  Then I see a "Full - Join Waitlist" button
  And the class is visually marked as full
  And I can still view class details

Scenario: [Edge Case] Search with no results
  Given I am on the class browse page
  When I apply filters that match no classes
  Then I see a "No classes found" message
  And suggestions to adjust my filters
  And a link to view the full schedule

Scenario: [Error Case] Handle network disconnection gracefully
  Given I am browsing classes
  When my WebSocket connection drops
  Then I see a reconnecting indicator
  And the page attempts to reconnect automatically
  And data is re-synced when connection is restored
```

**Acceptance Criteria**:

1. Class list displays all scheduled classes with real-time availability counts
2. Filters work for: date range, time of day, instructor, class type, studio location
3. LiveView streams handle class list updates efficiently (no full re-renders)
4. PubSub broadcasts booking events to update availability across all connected clients
5. Full classes display "Join Waitlist" option instead of "Book Now"
6. UI is responsive on mobile, tablet, and desktop
7. Search/filter state persists when navigating back from class details
8. Loading states and skeleton screens display while fetching data
9. Empty states provide helpful guidance when no classes match filters
10. All interactions work without full page reloads (LiveView patches)

**Technical Implementation Details**:

**Reusable Modules/Classes**:
- `PilatesOnPhx.Classes` domain for class queries
- `PilatesOnPhx.Bookings` domain for availability calculations
- `PilatesOnPhxWeb.CoreComponents` for UI primitives
- Ash calculations for `available_spots` on Class resource

**Implementation Patterns**:
- LiveView streams for efficient class list rendering (AGENTS.md lines 214-239)
- PubSub topic: `classes:availability` for real-time updates
- Ash aggregates for booking counts: `count(:bookings, filter: [status: :confirmed])`
- LiveView `handle_info/2` for PubSub message handling
- `Phoenix.Component.to_form/2` for filter form handling (AGENTS.md lines 274-311)

**Code Organization**:
- LiveView: `lib/pilates_on_phx_web/live/class_live/index.ex`
- Components: `lib/pilates_on_phx_web/live/class_live/class_card.ex`
- Filter component: `lib/pilates_on_phx_web/live/class_live/filter_form.ex`

**Security Considerations**:
- Multi-tenant isolation: Ensure clients only see classes for their assigned studios
- Authorization policy: Clients can view public class schedules
- Rate limiting on filter changes to prevent abuse
- Sanitize all filter inputs

**Performance Considerations**:
- Index on `classes.start_time`, `classes.studio_id`, `classes.instructor_id`
- Eager load instructor and class_type relationships
- Limit initial query to next 30 days to avoid large datasets
- Use LiveView streams with `reset: true` for filter changes
- Cache class type and instructor lists for filter dropdowns

**Testing Strategy**:
- Unit tests for Ash queries with various filter combinations
- LiveView tests for filter interactions and UI updates
- Integration tests for PubSub broadcast handling
- Test authorization policies for multi-tenant isolation
- Performance tests for large class schedules (100+ classes)

**Supporting Documentation**:
- CLAUDE.md lines 145-175: LiveView patterns
- AGENTS.md lines 204-211: LiveView guidelines
- AGENTS.md lines 214-239: LiveView streams for collections
- AGENTS.md lines 254-269: LiveView testing patterns

**Dependencies**: PHX-2 (Class resource), PHX-4 (Booking resource)

**Estimate**: 5 story points

---

### PHX-10: Class Booking Workflow with Real-Time Validation

**Title**: Implement LiveView class booking flow with instant availability validation

**User Story**:  
As a client, I can book a class with real-time availability validation and immediate confirmation, so that I can secure my spot without booking conflicts.

**Description**:  
Create a seamless booking workflow using LiveView that validates availability in real-time, deducts package credits, and handles concurrent booking attempts gracefully using database transactions and optimistic locking.

**Use Cases**:

```gherkin
Scenario: [Happy Path] Book a class with available spots
  Given I am a logged-in client with an active package
  When I click "Book Now" on a class with available spots
  Then I see a booking confirmation modal
  And the modal shows class details, time, and credit cost
  When I confirm the booking
  Then my booking is created successfully
  And I see a success message with booking confirmation
  And my package credits are deducted
  And the class availability count decreases by 1
  And I receive a booking confirmation email

Scenario: [Happy Path] View booking confirmation details
  Given I have successfully booked a class
  When I view my booking confirmation
  Then I see class name, date, time, instructor, and studio location
  And I see my booking reference number
  And I see options to add to calendar or cancel booking
  And I see cancellation policy information

Scenario: [Edge Case] Attempt to book when class becomes full
  Given a class has 1 available spot
  When I click "Book Now" at the same time as another client
  And the other client's booking completes first
  Then I see a message "This class just filled up"
  And I am offered to join the waitlist instead
  And no charge is applied to my account

Scenario: [Edge Case] Book with insufficient package credits
  Given I have an active package with 0 credits remaining
  When I attempt to book a class
  Then I see an error "Insufficient credits"
  And I am shown options to purchase a new package
  And no booking is created

Scenario: [Error Case] Handle booking timeout
  Given I start the booking process
  When the booking takes longer than 30 seconds
  Then I see a timeout error message
  And the booking is rolled back
  And I am prompted to try again

Scenario: [Error Case] Handle duplicate booking attempt
  Given I have already booked a specific class
  When I attempt to book the same class again
  Then I see an error "You have already booked this class"
  And I am shown my existing booking details
```

**Acceptance Criteria**:

1. Booking form validates package credits before allowing submission
2. Real-time availability check prevents overbooking using DB constraints
3. Concurrent booking attempts are handled gracefully with proper error messages
4. Successful booking triggers: database record creation, credit deduction, email confirmation
5. Optimistic UI updates with rollback on error
6. Booking confirmation shows all relevant class and booking details
7. Cancellation policy is clearly displayed before booking confirmation
8. Client cannot book same class twice
9. Client cannot book overlapping classes
10. All booking operations are atomic (succeed or fail completely)

**Technical Implementation Details**:

**Reusable Modules/Classes**:
- Ash action: `PilatesOnPhx.Bookings.Booking` resource with `:book_class` action
- `PilatesOnPhx.Packages.Package` resource with `:deduct_credit` action
- Ash Notifier for sending booking confirmation emails
- Oban job: `PilatesOnPhx.Workers.BookingConfirmationEmailWorker`

**Implementation Patterns**:
- Ash multi-resource transaction for atomic booking + credit deduction
- Database unique constraint on `bookings(client_id, class_id)` to prevent duplicates
- Ash calculation for `can_book?` validation
- Ash policy for booking authorization
- LiveView `push_navigate/2` to booking confirmation page (AGENTS.md line 206)

**Code Organization**:
- LiveView: `lib/pilates_on_phx_web/live/booking_live/new.ex`
- Ash action: `lib/pilates_on_phx/bookings/resources/booking.ex` - `:book_class` action
- Confirmation page: `lib/pilates_on_phx_web/live/booking_live/show.ex`

**Security Considerations**:
- Verify client owns the package being used for payment
- Multi-tenant check: Client can only book classes at studios they have access to
- Rate limiting: Max 5 booking attempts per minute per client
- CSRF protection on booking form submission
- Audit log all booking transactions

**Performance Considerations**:
- Use database transaction with `FOR UPDATE` lock on class capacity check
- Index on `bookings(client_id, class_id)` for duplicate check
- Index on `bookings(class_id, status)` for availability count
- Background job for email sending (don't block booking response)
- Set transaction timeout to 30 seconds

**Testing Strategy**:
- Test concurrent booking attempts with 10+ simultaneous clients
- Test booking with various package credit scenarios (sufficient, insufficient, expired)
- Test database constraint violations and error handling
- Test optimistic locking and rollback scenarios
- Integration test full booking flow including email delivery
- Test authorization policies for multi-tenant isolation

**Supporting Documentation**:
- CLAUDE.md lines 87-97: Ash actions and changesets
- AGENTS.md lines 271-311: Form handling patterns
- CLAUDE.md lines 145-175: Background jobs with Oban

**Dependencies**: PHX-2 (Class), PHX-4 (Booking), PHX-5 (Package)

**Estimate**: 8 story points

---

### PHX-11: Client Dashboard with Bookings & Credits

**Title**: Build client dashboard with upcoming bookings and package credits

**User Story**:  
As a client, I can view my upcoming class bookings and package credit balance in one dashboard, so that I can manage my schedule and track my remaining credits.

**Description**:  
Create a comprehensive client dashboard using LiveView that displays upcoming bookings, past class history, current package credits, and waitlist status. Real-time updates via PubSub when bookings change.

**Use Cases**:

```gherkin
Scenario: [Happy Path] View upcoming bookings
  Given I am a logged-in client with 3 upcoming bookings
  When I navigate to my dashboard
  Then I see my next 3 bookings sorted by date
  And each booking shows class name, date, time, instructor, and location
  And I see a countdown "Starting in X hours" for classes within 24 hours
  And I can click to view full booking details

Scenario: [Happy Path] Cancel a booking
  Given I have an upcoming booking
  When I click "Cancel Booking" on a booking
  Then I see a confirmation modal explaining the cancellation policy
  When I confirm cancellation
  Then the booking is cancelled
  And my package credit is refunded (if within policy)
  And I see a success message
  And the booking moves to "Past Bookings" as cancelled

Scenario: [Happy Path] View package credit balance
  Given I have an active 10-class package with 7 credits remaining
  When I view my dashboard
  Then I see "7 of 10 credits remaining"
  And I see package expiration date
  And I see a visual progress bar showing credit usage
  And I can click to view credit usage history

Scenario: [Edge Case] View dashboard with no bookings
  Given I have no upcoming bookings
  When I view my dashboard
  Then I see a message "No upcoming classes"
  And I see a "Browse Classes" call-to-action button
  And I still see my package credit information

Scenario: [Edge Case] View waitlist status
  Given I am on a waitlist for 2 classes
  When I view my dashboard
  Then I see a "Waitlist" section
  And each waitlist entry shows class details and my position
  And I can remove myself from the waitlist

Scenario: [Error Case] Handle expired package
  Given my package has expired
  When I view my dashboard
  Then I see a warning banner "Your package has expired"
  And I see options to renew or purchase a new package
  And expired package details are still visible but marked as expired
```

**Acceptance Criteria**:

1. Dashboard displays upcoming bookings sorted chronologically
2. Each booking shows: class name, date/time, instructor, studio, cancellation option
3. Package credit balance shows: credits remaining, total credits, expiration date
4. Waitlist section displays all active waitlist entries with position
5. Real-time updates when bookings are added/cancelled via PubSub
6. Cancellation flow validates cancellation policy (e.g., 12-hour advance notice)
7. Credit refunds are processed correctly based on cancellation timing
8. Past bookings tab shows class history with attendance status
9. Mobile-responsive layout with collapsible sections
10. Empty states provide helpful guidance and CTAs

**Technical Implementation Details**:

**Reusable Modules/Classes**:
- Ash query: `PilatesOnPhx.Bookings.list_client_bookings/2` with filters and preloads
- Ash calculation: `Package.credits_remaining`
- Ash action: `Booking.cancel` with credit refund logic
- PubSub topic: `client:{client_id}:bookings` for real-time updates

**Implementation Patterns**:
- LiveView streams for booking lists (AGENTS.md lines 214-239)
- LiveView `handle_info/2` for PubSub updates
- Ash preloads: `[:class, :instructor, :studio, :package]`
- Ash policies to ensure clients only see their own data
- Phoenix.Component for reusable booking card

**Code Organization**:
- LiveView: `lib/pilates_on_phx_web/live/client_live/dashboard.ex`
- Components: `lib/pilates_on_phx_web/live/client_live/booking_card.ex`
- Components: `lib/pilates_on_phx_web/live/client_live/package_card.ex`

**Security Considerations**:
- Authorization: Clients can only view their own dashboard
- Multi-tenant: Scope all queries to client's ID
- Validate cancellation permissions (owner of booking)
- Audit log all cancellation actions

**Performance Considerations**:
- Limit upcoming bookings query to next 90 days
- Index on `bookings(client_id, status, start_time)`
- Eager load all required associations in single query
- Cache package credit calculations

**Testing Strategy**:
- Test dashboard with various booking states (none, few, many)
- Test cancellation flow with different timing scenarios
- Test credit refund logic based on cancellation policy
- Test PubSub real-time updates
- Test authorization for multi-client scenarios
- Integration test full cancellation workflow

**Supporting Documentation**:
- AGENTS.md lines 115-122: Ecto preloading patterns
- AGENTS.md lines 214-239: LiveView streams
- CLAUDE.md lines 145-175: Authorization policies

**Dependencies**: PHX-4 (Booking), PHX-5 (Package), PHX-3 (Client)

**Estimate**: 8 story points

---

### PHX-12: Instructor Dashboard with Class Management

**Title**: Create instructor dashboard for class management and attendance tracking

**User Story**:  
As an instructor, I can view my upcoming classes, manage class details, and track client attendance, so that I can efficiently manage my teaching schedule.

**Description**:  
Build an instructor-focused dashboard using LiveView that shows assigned classes, client rosters, attendance tracking, and class notes. Real-time roster updates as clients book or cancel.

**Use Cases**:

```gherkin
Scenario: [Happy Path] View assigned classes
  Given I am a logged-in instructor
  When I navigate to my dashboard
  Then I see all classes assigned to me for the next 30 days
  And each class shows date, time, class type, booked count, and capacity
  And classes are organized by date with today's classes at the top

Scenario: [Happy Path] View class roster
  Given I have a class scheduled for today with 8 bookings
  When I click on the class
  Then I see the full roster of 8 clients
  And each client shows name, booking status, and attendance status
  And I can mark each client as attended or no-show
  And I see any waitlist clients at the bottom

Scenario: [Happy Path] Mark attendance
  Given I am viewing a class roster
  When I mark a client as "Attended"
  Then the attendance status updates immediately
  And the client's attendance count increments
  And I see a visual confirmation
  And the change is saved to the database

Scenario: [Edge Case] View class with no bookings
  Given I have a class with 0 bookings
  When I view the class roster
  Then I see a message "No bookings yet"
  And I see the waitlist count if any
  And I can still add class notes

Scenario: [Edge Case] Handle late booking during class
  Given I am viewing a class roster during class time
  When a client books the class late
  Then the roster updates automatically via PubSub
  And I see a notification "New booking: [Client Name]"
  And the new client appears in the roster

Scenario: [Error Case] Handle roster load failure
  Given I attempt to view a class roster
  When the roster fails to load due to network error
  Then I see an error message "Unable to load roster"
  And I see a "Retry" button
  And I can still view other classes
```

**Acceptance Criteria**:

1. Dashboard displays all instructor-assigned classes for next 30 days
2. Each class card shows: date/time, class type, booking count/capacity, studio
3. Class detail page shows full roster with client names and booking status
4. Attendance can be marked via checkbox or quick-action buttons
5. Attendance updates persist immediately to database
6. Real-time roster updates via PubSub when bookings change
7. Waitlist clients are shown separately from confirmed bookings
8. Instructor can add private notes to each class
9. Past classes show attendance summary and completion status
10. Mobile-optimized for tablet-based check-in

**Technical Implementation Details**:

**Reusable Modules/Classes**:
- Ash query: `PilatesOnPhx.Classes.list_instructor_classes/2`
- Ash action: `Booking.mark_attended` with timestamp
- PubSub topic: `class:{class_id}:roster` for real-time updates
- Ash calculation: `Class.attendance_rate`

**Implementation Patterns**:
- LiveView streams for class list and roster
- LiveView `phx-click` for quick attendance marking
- Ash policies: Instructor can only view their assigned classes
- Ash aggregates for booking counts and attendance stats

**Code Organization**:
- LiveView: `lib/pilates_on_phx_web/live/instructor_live/dashboard.ex`
- LiveView: `lib/pilates_on_phx_web/live/instructor_live/class_show.ex`
- Component: `lib/pilates_on_phx_web/live/instructor_live/roster_table.ex`

**Security Considerations**:
- Authorization: Instructors can only view classes assigned to them
- Multi-tenant: Scope queries to instructor's studio(s)
- Audit log all attendance changes
- Validate instructor owns the class before marking attendance

**Performance Considerations**:
- Index on `classes(instructor_id, start_time)`
- Index on `bookings(class_id, status)`
- Preload all bookings with client info in single query
- Cache attendance statistics

**Testing Strategy**:
- Test dashboard with various class counts (0, 1, 10+)
- Test attendance marking and persistence
- Test PubSub roster updates
- Test authorization for multiple instructors
- Integration test full check-in workflow

**Supporting Documentation**:
- AGENTS.md lines 214-239: LiveView streams
- CLAUDE.md lines 145-175: Authorization policies

**Dependencies**: PHX-2 (Class), PHX-4 (Booking), PHX-7 (Instructor)

**Estimate**: 8 story points

---

### PHX-13: Owner/Admin Dashboard with Analytics

**Title**: Build owner dashboard with studio analytics and management tools

**User Story**:  
As a studio owner, I can view real-time analytics, manage staff, and monitor business performance, so that I can make informed decisions about my studio operations.

**Description**:  
Create a comprehensive admin dashboard using LiveView with real-time metrics, charts, and management interfaces for multi-studio oversight. Leverages Ash aggregates and calculations for efficient data reporting.

**Use Cases**:

```gherkin
Scenario: [Happy Path] View studio performance metrics
  Given I am a logged-in studio owner
  When I navigate to the admin dashboard
  Then I see key metrics for the current month:
    | Metric | Description |
    | Total Bookings | Count of all confirmed bookings |
    | Revenue | Total package sales |
    | Attendance Rate | Percentage of bookings attended |
    | Class Utilization | Average capacity filled |
  And I can filter metrics by date range and studio location

Scenario: [Happy Path] View booking trends chart
  Given I am viewing the admin dashboard
  When I view the "Bookings Over Time" chart
  Then I see a line chart showing daily booking counts for the past 30 days
  And the chart updates in real-time as new bookings are made
  And I can toggle between daily, weekly, and monthly views

Scenario: [Happy Path] Manage instructors
  Given I am viewing the admin dashboard
  When I click on "Manage Instructors"
  Then I see a list of all active instructors
  And I can add new instructors
  And I can edit instructor details
  And I can deactivate instructors
  And I see each instructor's upcoming class count

Scenario: [Edge Case] View dashboard for multiple studios
  Given I own 3 studio locations
  When I view the admin dashboard
  Then I see aggregated metrics across all studios
  And I can filter to view metrics for individual studios
  And I see a studio comparison table

Scenario: [Edge Case] View dashboard with no data
  Given my studio has just opened with no bookings yet
  When I view the admin dashboard
  Then I see all metrics showing "0" or "No data"
  And I see helpful onboarding tips
  And I see links to set up classes and invite clients

Scenario: [Error Case] Handle metric calculation timeout
  Given the dashboard is calculating complex metrics
  When a calculation takes longer than 10 seconds
  Then I see a loading indicator
  And I see a message "Loading data..."
  And the dashboard attempts to load data in smaller chunks
```

**Acceptance Criteria**:

1. Dashboard displays key metrics: bookings, revenue, attendance, utilization
2. Charts show booking trends with daily/weekly/monthly toggle
3. Metrics update in real-time via PubSub
4. Multi-studio owners can filter by studio location
5. Instructor management interface allows CRUD operations
6. Class schedule overview shows all upcoming classes across studios
7. Export functionality for metrics data (CSV download)
8. Date range picker for custom reporting periods
9. Mobile-responsive with collapsible sections
10. Role-based access: Owners see all data, Studio Managers see their studio only

**Technical Implementation Details**:

**Reusable Modules/Classes**:
- Ash aggregate queries for metrics calculations
- `PilatesOnPhx.Analytics` domain module for reporting
- Ash calculation: `Studio.monthly_revenue`, `Studio.attendance_rate`
- LiveView async assigns for expensive calculations
- Chart library: Chartkick or Contex for Elixir

**Implementation Patterns**:
- LiveView `assign_async/3` for loading metrics without blocking (Phoenix 1.7+)
- Ash aggregates for efficient metrics: `count(:bookings)`, `sum(:packages, :price)`
- PubSub topic: `analytics:updates` for real-time metric changes
- Ash policies for owner-level authorization
- LiveView handle_async for CSV export generation

**Code Organization**:
- LiveView: `lib/pilates_on_phx_web/live/admin_live/dashboard.ex`
- Domain: `lib/pilates_on_phx/analytics/metrics.ex`
- Components: `lib/pilates_on_phx_web/live/admin_live/metric_card.ex`
- Export: `lib/pilates_on_phx/analytics/exporters/csv_exporter.ex`

**Security Considerations**:
- Authorization: Only studio owners and managers can access admin dashboard
- Multi-tenant: Owners only see studios they own
- Studio Managers only see their assigned studio
- Audit log all administrative actions
- Rate limiting on export downloads

**Performance Considerations**:
- Use database materialized views for complex metrics
- Cache metrics with 5-minute TTL
- Paginate long lists (instructors, classes)
- Index on all fields used in aggregate queries
- Use Ash calculations for derived metrics instead of runtime computation
- Background job for generating large exports

**Testing Strategy**:
- Test metric calculations with known datasets
- Test authorization for different owner/manager scenarios
- Test real-time updates via PubSub
- Test CSV export generation and download
- Performance test with large datasets (1000+ bookings)
- Integration test full admin workflow

**Supporting Documentation**:
- Ash aggregates documentation
- LiveView async assigns patterns
- CLAUDE.md lines 145-175: Authorization policies

**Dependencies**: All Sprint 1 resources (PHX-1 through PHX-8)

**Estimate**: 13 story points

---

### PHX-14: User Profile Management

**Title**: Implement user profile editing with photo upload and preferences

**User Story**:  
As a user, I can update my profile information including photo, contact details, and preferences, so that my account information stays current and personalized.

**Description**:  
Create a user profile management interface using LiveView with form validation, image upload handling, and preference management. Supports profile photos, emergency contacts, health information, and notification preferences.

**Use Cases**:

```gherkin
Scenario: [Happy Path] Update basic profile information
  Given I am a logged-in user
  When I navigate to my profile settings
  Then I see a form with my current information:
    | Field | Description |
    | Full Name | First and last name |
    | Email | Primary email address |
    | Phone | Mobile phone number |
    | Emergency Contact | Name and phone |
  When I update my phone number and click "Save"
  Then I see a success message "Profile updated"
  And my phone number is updated in the database

Scenario: [Happy Path] Upload profile photo
  Given I am editing my profile
  When I click "Upload Photo"
  And I select a JPEG image file
  Then I see a preview of the uploaded image
  When I click "Save"
  Then the photo is uploaded to cloud storage
  And my profile displays the new photo
  And the old photo is deleted from storage

Scenario: [Happy Path] Update notification preferences
  Given I am editing my profile
  When I navigate to the "Notifications" tab
  Then I see checkboxes for notification types:
    | Type | Default |
    | Class Reminders | Enabled |
    | Booking Confirmations | Enabled |
    | Promotional Emails | Disabled |
    | SMS Notifications | Disabled |
  When I toggle "SMS Notifications" to enabled
  And I save my preferences
  Then SMS notifications are enabled for my account

Scenario: [Edge Case] Upload oversized image
  Given I am uploading a profile photo
  When I select an image larger than 5MB
  Then I see an error "Image must be smaller than 5MB"
  And I can select a different image
  And no upload occurs

Scenario: [Edge Case] Update email to existing email
  Given I am editing my profile
  When I change my email to an email already in use
  And I click "Save"
  Then I see an error "This email is already registered"
  And my email is not changed

Scenario: [Error Case] Handle upload failure
  Given I am uploading a profile photo
  When the upload to cloud storage fails
  Then I see an error message "Upload failed. Please try again"
  And my profile photo remains unchanged
  And I can retry the upload
```

**Acceptance Criteria**:

1. Profile form displays all user editable fields with current values
2. Form validation prevents invalid data (email format, required fields)
3. Profile photo upload supports JPEG, PNG with 5MB size limit
4. Image is resized to 300x300px thumbnail before storage
5. Old profile photo is deleted when new photo is uploaded
6. Emergency contact information is stored securely
7. Notification preferences are applied to future communications
8. Email change requires verification via confirmation link
9. Password change requires current password verification
10. Form shows loading state during save and success/error feedback

**Technical Implementation Details**:

**Reusable Modules/Classes**:
- Ash action: `User.update_profile` with validations
- LiveView uploads for file handling (Phoenix.LiveView.Uploads)
- Image processing: `:mogrify` library for resizing
- Cloud storage: ExAws for S3 or local storage in dev
- Ash Notifier for email verification on email change

**Implementation Patterns**:
- LiveView uploads with `allow_upload/3` (AGENTS.md file upload patterns)
- `Phoenix.Component.to_form/2` for form handling
- LiveView `handle_progress/3` for upload progress
- LiveView `consume_uploaded_entries/3` for processing uploads
- Ash validations for email uniqueness and format

**Code Organization**:
- LiveView: `lib/pilates_on_phx_web/live/profile_live/edit.ex`
- Upload handler: `lib/pilates_on_phx/accounts/profile_photo_uploader.ex`
- Image processor: `lib/pilates_on_phx/accounts/image_processor.ex`

**Security Considerations**:
- Validate file type and size server-side (don't trust client)
- Scan uploaded images for malicious content
- Store images in user-specific directories
- Use signed URLs for accessing private images
- Validate email change with confirmation link
- Require current password for sensitive changes

**Performance Considerations**:
- Resize images in background job to avoid blocking UI
- Use progressive upload with chunking for large files
- Store thumbnails separate from original images
- CDN for serving profile images
- Cache user profile data

**Testing Strategy**:
- Test form validation for all field types
- Test image upload with various file types and sizes
- Test email uniqueness validation
- Test notification preference persistence
- Integration test full profile update workflow
- Test concurrent profile updates (optimistic locking)

**Supporting Documentation**:
- Phoenix LiveView uploads documentation
- AGENTS.md lines 271-311: Form handling
- CLAUDE.md lines 87-97: Ash validations

**Dependencies**: PHX-1 (User resource)

**Estimate**: 8 story points

---

## SPRINT 3: Background Jobs & Automations

**Goal**: Implement automated workflows using Oban and AshOban for notifications, recurring tasks, and system maintenance.

**Duration**: 2-3 weeks  
**Dependencies**: Sprint 2 (PHX-9 through PHX-14)  
**Priority**: High

---

### PHX-15: Class Reminder Notification System

**Title**: Implement automated class reminder emails and SMS notifications

**User Story**:  
As a client, I receive automated reminders for my upcoming classes via email and SMS, so that I don't forget my scheduled sessions.

**Description**:  
Build an Oban-based notification system that sends automated class reminders 24 hours and 2 hours before class start time. Supports both email (via Resend/SendGrid) and SMS (via Twilio). Uses AshOban for domain-aware job processing.

**Use Cases**:

```gherkin
Scenario: [Happy Path] Send 24-hour email reminder
  Given a client has a class booking for tomorrow at 10:00 AM
  When the reminder job runs at 10:00 AM today
  Then an email is sent to the client
  And the email contains class name, time, instructor, and studio location
  And the email includes a "Add to Calendar" link
  And the email includes cancellation policy information
  And the reminder is marked as sent in the database

Scenario: [Happy Path] Send 2-hour SMS reminder
  Given a client has a class booking for today at 2:00 PM
  And the client has SMS notifications enabled
  When the reminder job runs at 12:00 PM
  Then an SMS is sent to the client's mobile number
  And the SMS contains class time and location
  And the SMS includes a link to view booking details
  And the reminder is marked as sent

Scenario: [Happy Path] Skip reminder for cancelled booking
  Given a client booked a class but cancelled it
  When the reminder job runs
  Then no reminder is sent for the cancelled booking
  And no email or SMS is delivered

Scenario: [Edge Case] Handle client with no email
  Given a client booking has no email address
  When the email reminder job runs
  Then the job logs a warning
  And the job marks as failed with reason "No email address"
  And the job does not retry
  And an admin alert is created

Scenario: [Edge Case] Retry failed SMS delivery
  Given an SMS reminder fails due to network error
  When the job fails
  Then the job is retried up to 3 times with exponential backoff
  And if all retries fail, an admin alert is created
  And the reminder is marked as failed in the database

Scenario: [Error Case] Handle invalid phone number
  Given a client has an invalid phone number format
  When the SMS reminder job runs
  Then the SMS provider returns an error
  And the job logs the error
  And the job does not retry
  And an admin alert is created for data cleanup
```

**Acceptance Criteria**:

1. Oban jobs scheduled automatically when booking is created
2. Email reminders sent 24 hours before class start time
3. SMS reminders sent 2 hours before class (if client opted in)
4. Reminders include all relevant class information and cancellation policy
5. Failed deliveries are retried with exponential backoff (max 3 attempts)
6. Reminders not sent for cancelled bookings
7. Admin dashboard shows reminder delivery status and failures
8. Clients can opt-in/out of SMS reminders in profile settings
9. Rate limiting to prevent exceeding email/SMS provider limits
10. All reminder sends are logged for audit purposes

**Technical Implementation Details**:

**Reusable Modules/Classes**:
- Oban worker: `PilatesOnPhx.Workers.ClassReminderWorker`
- Email templates: `PilatesOnPhxWeb.Emails.ClassReminderEmail`
- SMS sender: `PilatesOnPhx.Notifications.SmsSender` (Twilio adapter)
- Email sender: `PilatesOnPhx.Mailer` (Resend/SendGrid adapter)
- Ash Notifier: `PilatesOnPhx.Bookings.Notifiers.BookingCreated`

**Implementation Patterns**:
- AshOban integration for scheduling jobs from Ash actions
- Oban cron for recurring reminder checks every hour
- Oban unique jobs to prevent duplicate reminders
- Ash action callback to schedule jobs on booking creation
- Template engine: Phoenix.View or Embedded Elixir for email HTML

**Code Organization**:
- Workers: `lib/pilates_on_phx/workers/class_reminder_worker.ex`
- Email templates: `lib/pilates_on_phx_web/emails/class_reminder_email.ex`
- SMS: `lib/pilates_on_phx/notifications/sms_sender.ex`
- Job scheduler: `lib/pilates_on_phx/bookings/job_scheduler.ex`

**Security Considerations**:
- Store Twilio and email provider API keys in environment variables
- Encrypt sensitive data in job payloads
- Validate phone numbers before sending SMS
- Rate limiting per client (max 10 SMS per day)
- Audit log all notification sends

**Performance Considerations**:
- Batch email sends to stay within provider rate limits
- Use Oban priority queues (high priority for 2-hour reminders)
- Index on `bookings(start_time, reminder_sent)` for efficient queries
- Use Oban's built-in rate limiting
- Separate queue for emails vs SMS for independent scaling

**Testing Strategy**:
- Unit test worker logic with mock email/SMS providers
- Integration test job scheduling from booking creation
- Test retry logic with simulated failures
- Test opt-out functionality
- Test job uniqueness (no duplicate reminders)
- Performance test with 1000+ concurrent jobs

**Supporting Documentation**:
- Oban documentation: https://hexdocs.pm/oban/
- AshOban integration patterns
- CLAUDE.md lines 145-175: Background jobs

**Dependencies**: PHX-4 (Booking), PHX-3 (Client), External services (Twilio, Resend/SendGrid)

**Estimate**: 13 story points

---

### PHX-16: Waitlist Promotion Automation

**Title**: Automate waitlist promotions when class spots become available

**User Story**:  
As a client on a waitlist, I am automatically promoted to a confirmed booking when a spot opens up, so that I can attend the class without manual intervention.

**Description**:  
Build an Oban-based waitlist promotion system that automatically promotes the next waitlist client when a booking is cancelled. Sends immediate notification to promoted client and handles credit deduction atomically.

**Use Cases**:

```gherkin
Scenario: [Happy Path] Promote from waitlist after cancellation
  Given a class is full with 10 bookings and 3 clients on waitlist
  And the waitlist order is: Alice (position 1), Bob (position 2), Carol (position 3)
  When a confirmed booking is cancelled
  Then Alice is automatically promoted to confirmed booking
  And Alice receives a booking confirmation email immediately
  And Alice receives an SMS notification (if opted in)
  And Alice's package credits are deducted
  And Alice's waitlist position is removed
  And Bob moves to position 1, Carol moves to position 2

Scenario: [Happy Path] Multiple promotions after multiple cancellations
  Given a class has 2 confirmed bookings cancelled within 1 minute
  And waitlist has Alice and Bob
  When the promotion job runs
  Then Alice is promoted first
  And Bob is promoted second
  And both receive confirmation notifications
  And both have credits deducted
  And waitlist is now empty

Scenario: [Edge Case] Skip promotion if client has insufficient credits
  Given Alice is position 1 on waitlist
  And Alice has 0 package credits remaining
  When a spot opens up
  Then Alice is NOT promoted
  And Alice receives an email "Insufficient credits - please purchase package"
  And Bob (position 2) is promoted instead
  And Alice remains on waitlist

Scenario: [Edge Case] Handle client with expired package
  Given Alice is position 1 on waitlist
  And Alice's package has expired
  When a spot opens up
  Then Alice is NOT promoted
  And Alice receives an email about expired package
  And next eligible waitlist client is promoted
  And Alice is removed from waitlist

Scenario: [Error Case] Handle failed credit deduction
  Given Alice is promoted from waitlist
  When the credit deduction fails due to database error
  Then the entire promotion is rolled back
  And Alice remains on waitlist at position 1
  And no notification is sent
  And the job is retried
  And an admin alert is created

Scenario: [Error Case] Handle concurrent promotions conflict
  Given 2 spots open up simultaneously
  And only 1 eligible client on waitlist
  When 2 promotion jobs run concurrently
  Then only 1 booking is created (using database constraint)
  And the duplicate job fails gracefully
  And the client receives only 1 confirmation
```

**Acceptance Criteria**:

1. Oban job triggered automatically when booking is cancelled
2. Next waitlist client is promoted in order (FIFO)
3. Promotion is atomic: booking creation + credit deduction + notification
4. Client is skipped if they lack sufficient/valid credits
5. Promoted client receives immediate email and SMS confirmation
6. Waitlist positions are recalculated after promotion
7. Failed promotions are retried with proper error handling
8. Concurrent promotions handled gracefully with database locks
9. All promotions logged for audit trail
10. Admin dashboard shows promotion success/failure metrics

**Technical Implementation Details**:

**Reusable Modules/Classes**:
- Oban worker: `PilatesOnPhx.Workers.WaitlistPromotionWorker`
- Ash action: `Booking.promote_from_waitlist` (atomic action)
- Ash calculation: `Waitlist.next_eligible_client`
- PubSub broadcast for real-time dashboard updates
- Ash Notifier: `PilatesOnPhx.Bookings.Notifiers.BookingCancelled`

**Implementation Patterns**:
- Ash atomic actions for transaction safety
- Database transaction with `FOR UPDATE SKIP LOCKED` for waitlist locking
- Oban unique job to prevent duplicate promotions
- Ash policy to validate client eligibility
- AshOban for scheduling promotion jobs

**Code Organization**:
- Worker: `lib/pilates_on_phx/workers/waitlist_promotion_worker.ex`
- Action: `lib/pilates_on_phx/bookings/resources/booking.ex` - `:promote_from_waitlist`
- Notifier: `lib/pilates_on_phx/bookings/notifiers/booking_cancelled.ex`

**Security Considerations**:
- Validate client eligibility before promotion
- Use database constraints to prevent overbooking
- Audit log all promotion attempts and results
- Prevent manual promotion bypassing eligibility rules

**Performance Considerations**:
- Index on `waitlist_entries(class_id, position, status)`
- Use database lock timeout (5 seconds) to prevent long waits
- Process promotions in background to avoid blocking cancellation
- Batch notifications if multiple promotions occur

**Testing Strategy**:
- Test FIFO waitlist ordering
- Test atomic promotion with rollback scenarios
- Test concurrent promotion attempts
- Test eligibility validation (credits, package expiry)
- Integration test full promotion flow with notifications
- Test database constraint enforcement

**Supporting Documentation**:
- Oban unique jobs documentation
- Ash atomic actions patterns
- CLAUDE.md lines 145-175: Background jobs

**Dependencies**: PHX-4 (Booking), PHX-6 (Waitlist), PHX-5 (Package)

**Estimate**: 13 story points

---

### PHX-17: Recurring Class Generation

**Title**: Automate weekly class schedule generation from recurring templates

**User Story**:  
As a studio owner, I can define recurring class templates that automatically generate weekly class schedules, so that I don't have to manually create classes every week.

**Description**:  
Build an Oban cron-based system that automatically generates class instances from recurring class templates. Runs weekly to create the next week's schedule, with support for exclusion dates, instructor rotations, and studio-specific rules.

**Use Cases**:

```gherkin
Scenario: [Happy Path] Generate classes from weekly template
  Given a recurring template exists:
    | Field | Value |
    | Class Type | Reformer Pilates |
    | Day of Week | Monday |
    | Time | 10:00 AM |
    | Duration | 60 minutes |
    | Instructor | Sarah Johnson |
    | Capacity | 10 |
    | Studio | Downtown Studio |
  When the weekly generation job runs on Sunday at midnight
  Then a new class is created for next Monday at 10:00 AM
  And the class has all template properties
  And the class is available for booking immediately

Scenario: [Happy Path] Generate multiple classes from templates
  Given 15 recurring templates exist for the studio
  When the weekly generation job runs
  Then 15 new classes are created for next week
  And each class matches its template configuration
  And all classes are bookable

Scenario: [Happy Path] Skip holiday exclusion dates
  Given a recurring template for Monday classes
  And next Monday is marked as a holiday (studio closed)
  When the weekly generation job runs
  Then NO class is created for that Monday
  And classes for other days are created normally

Scenario: [Edge Case] Handle instructor rotation
  Given a recurring template with 3 rotating instructors
  And the rotation pattern is: Sarah, Mike, Jennifer
  And last week's class was taught by Mike
  When the weekly generation job runs
  Then the new class is assigned to Jennifer (next in rotation)
  And the rotation state is saved for next week

Scenario: [Edge Case] Handle instructor unavailability
  Given a recurring template assigned to Sarah
  And Sarah has marked next Monday as unavailable
  When the weekly generation job runs
  Then the class is created but marked as "Needs Instructor"
  And an admin alert is created for manual assignment

Scenario: [Error Case] Handle duplicate class prevention
  Given a class already exists for next Monday at 10:00 AM
  When the generation job runs
  Then no duplicate class is created
  And the existing class is unchanged
  And the job logs a skip notice
```

**Acceptance Criteria**:

1. Oban cron job runs weekly (Sunday midnight) to generate next week's classes
2. Each recurring template generates one class per week (or per recurrence rule)
3. Generated classes inherit all template properties (type, time, capacity, instructor)
4. Holiday exclusion dates prevent class generation
5. Instructor rotation patterns are respected and maintained
6. Duplicate detection prevents creating existing classes
7. Admin interface to create/edit recurring templates
8. Admin can manually trigger generation for date ranges
9. Generation failures are logged and alerted to admins
10. Generated classes appear immediately in client booking interface

**Technical Implementation Details**:

**Reusable Modules/Classes**:
- Oban worker: `PilatesOnPhx.Workers.RecurringClassGeneratorWorker`
- Ash resource: `PilatesOnPhx.Classes.RecurringTemplate`
- Ash action: `RecurringTemplate.generate_classes` with date range
- Holiday calendar: `PilatesOnPhx.Studios.HolidayCalendar`
- Rotation state: `PilatesOnPhx.Classes.InstructorRotation`

**Implementation Patterns**:
- Oban cron plugin for weekly scheduling
- Ash atomic batch actions for creating multiple classes efficiently
- Database unique constraint on `classes(studio_id, start_time, class_type_id)`
- Ash calculation for next instructor in rotation
- Idempotent job design (safe to run multiple times)

**Code Organization**:
- Worker: `lib/pilates_on_phx/workers/recurring_class_generator_worker.ex`
- Template resource: `lib/pilates_on_phx/classes/resources/recurring_template.ex`
- Generator logic: `lib/pilates_on_phx/classes/class_generator.ex`
- Holiday calendar: `lib/pilates_on_phx/studios/resources/holiday_calendar.ex`

**Security Considerations**:
- Only admins can create/edit recurring templates
- Validate template parameters before generation
- Audit log all template changes and generations
- Multi-tenant isolation for studio-specific templates

**Performance Considerations**:
- Batch insert classes using Ash bulk actions
- Index on `classes(studio_id, start_time)`
- Limit generation to 4 weeks ahead to prevent large batches
- Run job during off-peak hours (midnight)
- Transaction timeout of 60 seconds for large batches

**Testing Strategy**:
- Test template-to-class mapping
- Test holiday exclusion logic
- Test instructor rotation patterns
- Test duplicate prevention
- Integration test full weekly generation workflow
- Performance test with 100+ templates

**Supporting Documentation**:
- Oban cron plugin documentation
- Ash bulk actions patterns
- CLAUDE.md lines 145-175: Background jobs

**Dependencies**: PHX-2 (Class), PHX-7 (Instructor), PHX-8 (Studio)

**Estimate**: 13 story points

---

### PHX-18: Package Expiration Warnings

**Title**: Send automated warnings before package expiration

**User Story**:  
As a client, I receive email notifications before my package expires, so that I can use my remaining credits or renew my package in time.

**Description**:  
Build an Oban-based notification system that sends automated warnings at 30 days, 7 days, and 1 day before package expiration. Includes personalized recommendations based on remaining credits.

**Use Cases**:

```gherkin
Scenario: [Happy Path] Send 30-day expiration warning
  Given a client has a package expiring in 30 days
  And the package has 5 credits remaining
  When the daily expiration check job runs
  Then an email is sent to the client
  And the email states "Your package expires in 30 days"
  And the email shows remaining credits (5 of 10)
  And the email includes a "Book Classes Now" link
  And the warning is marked as sent in database

Scenario: [Happy Path] Send 7-day urgent warning
  Given a client has a package expiring in 7 days
  And the package has 8 credits remaining
  When the daily expiration check job runs
  Then an urgent email is sent with subject "Package expiring soon!"
  And the email recommends booking multiple classes
  And the email includes upcoming class suggestions
  And the email includes renewal/purchase options

Scenario: [Happy Path] Send final 1-day warning
  Given a client has a package expiring tomorrow
  And the package has 2 credits remaining
  When the daily expiration check job runs
  Then a final warning email is sent
  And the email states "Last chance to use your credits"
  And the email has a red urgent banner
  And the email includes quick-book links to today's classes

Scenario: [Edge Case] Skip warning if package fully used
  Given a client has a package expiring in 30 days
  And the package has 0 credits remaining (all used)
  When the daily expiration check job runs
  Then NO warning email is sent
  And the job logs "Package fully used, no warning needed"

Scenario: [Edge Case] Skip warning if already sent
  Given a 30-day warning was sent yesterday
  And the package still expires in 30 days (time zone difference)
  When the daily expiration check job runs
  Then NO duplicate warning is sent
  And the job uses idempotency key to prevent duplicates

Scenario: [Error Case] Handle email delivery failure
  Given a client has a package expiring in 7 days
  When the warning email fails to send
  Then the job retries up to 3 times
  And if all retries fail, an admin alert is created
  And the failure is logged for manual follow-up
```

**Acceptance Criteria**:

1. Daily Oban cron job checks for packages nearing expiration
2. Warnings sent at 30 days, 7 days, and 1 day before expiration
3. Email content is personalized with remaining credits and recommendations
4. Fully used packages do not receive warnings
5. Duplicate warnings prevented using idempotency keys
6. Email includes quick links to book classes and renew package
7. Urgent warnings (7-day, 1-day) have higher email priority
8. Failed deliveries are retried and logged
9. Admin dashboard shows warning delivery metrics
10. Clients can opt-out of expiration warnings in preferences

**Technical Implementation Details**:

**Reusable Modules/Classes**:
- Oban worker: `PilatesOnPhx.Workers.PackageExpirationWarningWorker`
- Email templates: `PilatesOnPhxWeb.Emails.PackageExpirationEmail`
- Ash query: `Package.expiring_soon/1` with filters
- Recommendation engine: `PilatesOnPhx.Recommendations.ClassSuggester`

**Implementation Patterns**:
- Oban cron for daily execution at 9:00 AM
- Oban unique jobs with `:package_id` and `:warning_type` for idempotency
- Ash calculations for `days_until_expiration`, `credits_remaining`
- Email template variants for 30-day, 7-day, 1-day warnings
- AshOban integration for job scheduling

**Code Organization**:
- Worker: `lib/pilates_on_phx/workers/package_expiration_warning_worker.ex`
- Email: `lib/pilates_on_phx_web/emails/package_expiration_email.ex`
- Query: `lib/pilates_on_phx/packages/queries.ex`
- Recommendations: `lib/pilates_on_phx/recommendations/class_suggester.ex`

**Security Considerations**:
- Respect client opt-out preferences
- Encrypt package details in job payloads
- Audit log all warning sends
- Rate limit to prevent spam (max 1 warning per day per package)

**Performance Considerations**:
- Index on `packages(expiration_date, status)`
- Batch query packages expiring in all three windows (30, 7, 1 day)
- Limit query to active packages only
- Process warnings in batches of 100
- Use Oban rate limiting for email provider

**Testing Strategy**:
- Test warning logic for each time window (30, 7, 1 day)
- Test idempotency (no duplicate warnings)
- Test opt-out functionality
- Test email content personalization
- Integration test full warning workflow
- Test retry logic for failed deliveries

**Supporting Documentation**:
- Oban cron scheduling
- Email templating best practices
- CLAUDE.md lines 145-175: Background jobs

**Dependencies**: PHX-5 (Package), PHX-3 (Client)

**Estimate**: 8 story points

---

### PHX-19: Attendance Tracking Automation

**Title**: Automate attendance tracking and no-show handling

**User Story**:  
As a studio owner, I want automated tracking of client attendance and no-shows, so that I can monitor client engagement and enforce attendance policies.

**Description**:  
Build an Oban-based system that automatically marks bookings as "no-show" when clients don't check in by class start time. Sends follow-up communications and applies penalties per studio policy.

**Use Cases**:

```gherkin
Scenario: [Happy Path] Mark no-show after class start
  Given a client has a confirmed booking for a class starting at 10:00 AM
  And the client has not checked in by 10:00 AM
  When the no-show check job runs at 10:15 AM
  Then the booking is marked as "no-show"
  And the client's no-show count is incremented
  And a follow-up email is sent to the client
  And the credit is NOT refunded

Scenario: [Happy Path] Do not mark as no-show if attended
  Given a client has a confirmed booking for a class starting at 10:00 AM
  And the client checked in at 9:55 AM
  When the no-show check job runs at 10:15 AM
  Then the booking remains marked as "attended"
  And no no-show email is sent
  And the client's no-show count is unchanged

Scenario: [Happy Path] Apply penalty after multiple no-shows
  Given a client has accumulated 3 no-shows in the past month
  And studio policy is "3 strikes - temporary booking suspension"
  When the 3rd no-show is recorded
  Then the client's account is suspended from booking for 7 days
  And an email is sent explaining the suspension and policy
  And an admin notification is created

Scenario: [Edge Case] Handle late check-in
  Given a class starts at 10:00 AM with 10-minute grace period
  And a client checks in at 10:08 AM
  When the no-show check job runs at 10:15 AM
  Then the booking is marked as "attended - late"
  And no no-show penalty is applied
  And a gentle reminder email about punctuality is sent

Scenario: [Edge Case] Handle cancelled booking
  Given a client has a booking for today
  And the client cancelled the booking yesterday
  When the no-show check job runs
  Then the cancelled booking is ignored
  And no no-show is recorded

Scenario: [Error Case] Handle job failure during attendance update
  Given multiple bookings need no-show updates
  When the job fails midway due to database error
  Then already processed bookings remain updated
  And the job is retried for remaining bookings
  And an admin alert is created
```

**Acceptance Criteria**:

1. Oban job runs every 15 minutes to check for no-shows
2. Bookings are marked "no-show" if not checked in by start time + grace period
3. No-show counter increments for each no-show occurrence
4. Follow-up email sent to client after no-show
5. Studio-specific policies applied (e.g., suspension after X no-shows)
6. Late check-ins within grace period are marked as attended
7. Cancelled bookings are excluded from no-show checks
8. Admin dashboard shows no-show rates per client and class
9. Automated suspension emails explain policy and reinstatement process
10. No-show penalties are reversible by admin (manual override)

**Technical Implementation Details**:

**Reusable Modules/Classes**:
- Oban worker: `PilatesOnPhx.Workers.NoShowCheckerWorker`
- Ash action: `Booking.mark_no_show` with policy enforcement
- Ash calculation: `Client.no_show_count` (last 30 days)
- Studio policy: `PilatesOnPhx.Studios.AttendancePolicy`
- Email: `PilatesOnPhxWeb.Emails.NoShowEmail`

**Implementation Patterns**:
- Oban cron for recurring checks every 15 minutes
- Ash policy for penalty application based on no-show count
- Ash Notifier for sending follow-up emails
- Database query for bookings past start time without attendance
- Ash atomic action for incrementing no-show count

**Code Organization**:
- Worker: `lib/pilates_on_phx/workers/no_show_checker_worker.ex`
- Action: `lib/pilates_on_phx/bookings/resources/booking.ex` - `:mark_no_show`
- Policy: `lib/pilates_on_phx/studios/attendance_policy.ex`
- Email: `lib/pilates_on_phx_web/emails/no_show_email.ex`

**Security Considerations**:
- Only authorized staff can manually override no-shows
- Audit log all no-show markings and policy applications
- Multi-tenant isolation for studio-specific policies
- Prevent gaming the system (e.g., late cancellations)

**Performance Considerations**:
- Index on `bookings(start_time, status, checked_in_at)`
- Limit query to bookings within last 24 hours
- Batch process no-show updates (100 at a time)
- Run job during low-traffic periods when possible

**Testing Strategy**:
- Test no-show detection for various timing scenarios
- Test grace period handling
- Test policy enforcement (suspension after X no-shows)
- Test late check-in vs no-show logic
- Integration test full no-show workflow with email
- Test admin override functionality

**Supporting Documentation**:
- Oban recurring jobs
- Ash policies and rules
- CLAUDE.md lines 145-175: Background jobs

**Dependencies**: PHX-4 (Booking), PHX-3 (Client), PHX-8 (Studio)

**Estimate**: 8 story points

---

### PHX-20: Report Generation System

**Title**: Automate monthly business reports for studio owners

**User Story**:  
As a studio owner, I receive automated monthly business reports via email, so that I can track performance trends and make data-driven decisions.

**Description**:  
Build an Oban-based reporting system that generates comprehensive monthly business reports including revenue, attendance, client retention, and class utilization metrics. Reports are generated as PDF attachments and emailed to studio owners.

**Use Cases**:

```gherkin
Scenario: [Happy Path] Generate monthly revenue report
  Given today is the 1st of the month
  When the monthly report job runs at 6:00 AM
  Then a revenue report is generated for the previous month
  And the report includes:
    | Section | Content |
    | Revenue Summary | Total revenue, breakdown by package type |
    | Booking Stats | Total bookings, cancellation rate |
    | Attendance | Attendance rate, no-show rate |
    | Class Utilization | Average capacity filled per class type |
    | Top Classes | Most popular classes by booking count |
  And the report is generated as a PDF
  And the PDF is emailed to all studio owners
  And the report is stored in the database for historical access

Scenario: [Happy Path] Generate multi-studio report
  Given a studio owner owns 3 locations
  When the monthly report job runs
  Then a consolidated report is generated across all 3 studios
  And the report includes studio-by-studio comparisons
  And each studio's performance is highlighted
  And the owner receives one email with all studio data

Scenario: [Happy Path] Include year-over-year comparison
  Given the studio has been operating for over 1 year
  When the monthly report is generated
  Then the report includes YoY comparison metrics
  And growth/decline percentages are calculated
  And trends are visualized in charts

Scenario: [Edge Case] Handle new studio with no data
  Given a studio opened this month with no previous data
  When the monthly report job runs
  Then a report is generated with available data
  And sections with no data show "N/A - Insufficient data"
  And a welcome message for new studios is included

Scenario: [Edge Case] Skip report if owner opted out
  Given a studio owner has disabled monthly reports in settings
  When the monthly report job runs
  Then no report is generated for that owner
  And the job logs "Owner opted out of monthly reports"

Scenario: [Error Case] Handle PDF generation failure
  Given the report data is calculated successfully
  When PDF generation fails due to memory issue
  Then the job retries with smaller data chunks
  And if retry fails, the raw data is emailed as CSV
  And an admin alert is created
  And the owner is notified of the fallback format
```

**Acceptance Criteria**:

1. Oban cron job runs monthly (1st of month at 6:00 AM)
2. Report includes revenue, bookings, attendance, and utilization metrics
3. Report is generated as PDF with charts and tables
4. PDF is emailed to studio owners as attachment
5. Multi-studio owners receive consolidated reports
6. Year-over-year comparisons included when historical data available
7. Report stored in database for historical access via dashboard
8. Owners can manually trigger reports for custom date ranges
9. Failed generations fallback to CSV format
10. Opt-out option available in owner settings

**Technical Implementation Details**:

**Reusable Modules/Classes**:
- Oban worker: `PilatesOnPhx.Workers.MonthlyReportGeneratorWorker`
- Report generator: `PilatesOnPhx.Analytics.ReportGenerator`
- PDF library: `:pdf_generator` or `:puppeteer_pdf` for HTML-to-PDF
- Chart library: `:contex` for Elixir-native charts
- Email: `PilatesOnPhxWeb.Emails.MonthlyReportEmail`

**Implementation Patterns**:
- Oban cron for monthly scheduling (0 6 1 * *)
- Ash aggregates for efficient metric calculations
- HTML templates for report layout (converted to PDF)
- Background processing for large PDF generation
- S3/cloud storage for historical report PDFs

**Code Organization**:
- Worker: `lib/pilates_on_phx/workers/monthly_report_generator_worker.ex`
- Generator: `lib/pilates_on_phx/analytics/report_generator.ex`
- Templates: `lib/pilates_on_phx_web/templates/reports/monthly_report.html.heex`
- PDF: `lib/pilates_on_phx/analytics/pdf_generator.ex`

**Security Considerations**:
- Only owners receive reports for their studios
- PDF storage is access-controlled (signed URLs)
- Sensitive metrics are redacted for non-owner viewers
- Audit log report generation and access

**Performance Considerations**:
- Pre-calculate metrics during off-peak hours
- Cache report data for 24 hours after generation
- Generate PDF asynchronously to avoid blocking
- Use database materialized views for complex metrics
- Limit historical data queries to 13 months

**Testing Strategy**:
- Test metric calculations with known datasets
- Test PDF generation and formatting
- Test multi-studio aggregation
- Test YoY comparison logic
- Integration test full report generation and email delivery
- Performance test with large datasets (1 year of data)

**Supporting Documentation**:
- Oban cron scheduling
- PDF generation libraries for Elixir
- CLAUDE.md lines 145-175: Background jobs

**Dependencies**: All Sprint 1-2 resources, Analytics domain

**Estimate**: 13 story points

---

## SPRINT 4: Integrations & Advanced Features

**Goal**: Integrate third-party services for payments, communications, and calendar features. Add advanced functionality for production readiness.

**Duration**: 2-3 weeks  
**Dependencies**: Sprint 3 (PHX-15 through PHX-20)  
**Priority**: Medium-High

---

### PHX-21: Stripe Payment Integration

**Title**: Integrate Stripe for package purchases and subscription management

**User Story**:  
As a client, I can purchase class packages and memberships using credit card via Stripe, so that I can conveniently pay for classes online.

**Description**:  
Build a complete Stripe integration using `:stripity_stripe` library for one-time package purchases and recurring subscriptions. Includes checkout flow, webhook handling, and payment history.

**Use Cases**:

```gherkin
Scenario: [Happy Path] Purchase a class package
  Given I am a logged-in client
  When I select a "10-Class Package - $150" to purchase
  And I click "Checkout"
  Then I am redirected to Stripe Checkout page
  And I enter my credit card details
  When payment is successful
  Then I am redirected back to the app
  And I see a success message "Package purchased successfully"
  And a new package is created in my account with 10 credits
  And I receive a receipt email from Stripe
  And the package is immediately available for booking

Scenario: [Happy Path] Subscribe to monthly membership
  Given I am a logged-in client
  When I select "Unlimited Monthly - $200/month" subscription
  And I complete Stripe Checkout
  Then my subscription is created and activated
  And I am charged $200 immediately
  And I receive an unlimited credits package for the month
  And future charges will occur on the same day each month
  And I can cancel subscription anytime from my profile

Scenario: [Happy Path] View payment history
  Given I have made 3 package purchases in the past
  When I navigate to my payment history
  Then I see all 3 transactions listed
  And each transaction shows date, amount, package type, and receipt link
  And I can download receipts as PDF

Scenario: [Edge Case] Handle failed payment
  Given I am purchasing a package
  When my credit card is declined
  Then I am redirected back to the app with error message
  And no package is created
  And I see suggested next steps (update card, try different card)
  And no charge appears on my account

Scenario: [Edge Case] Handle webhook delay
  Given I complete Stripe checkout successfully
  When the webhook is delayed by 30 seconds
  Then I see a loading message "Processing payment..."
  And once webhook is received, the page updates automatically
  And my package appears without page refresh

Scenario: [Error Case] Handle subscription renewal failure
  Given I have an active monthly subscription
  When the renewal payment fails due to expired card
  Then I receive an email notification
  And my subscription status changes to "Past Due"
  And I have 7 days to update payment method
  And I can still use current month's credits
  And after 7 days, subscription is cancelled if not resolved
```

**Acceptance Criteria**:

1. Stripe Checkout integration for one-time package purchases
2. Stripe subscription support for recurring memberships
3. Webhook handler for payment success/failure events
4. Webhook handler for subscription events (created, renewed, cancelled)
5. Payment history page shows all transactions with receipts
6. Failed payments display user-friendly error messages
7. Successful payments immediately activate purchased package
8. Subscription management interface (cancel, update card)
9. Admin dashboard shows payment metrics and failed payment alerts
10. All payments comply with PCI-DSS (Stripe handles card data)

**Technical Implementation Details**:

**Reusable Modules/Classes**:
- Hex package: `:stripity_stripe` for Stripe API
- Ash resource: `PilatesOnPhx.Payments.Transaction`
- Ash resource: `PilatesOnPhx.Payments.Subscription`
- Webhook controller: `PilatesOnPhxWeb.StripeWebhookController`
- Checkout service: `PilatesOnPhx.Payments.CheckoutService`

**Implementation Patterns**:
- Stripe Checkout Sessions for payment UI
- Stripe Webhooks for event handling (payment.succeeded, etc.)
- Webhook signature verification for security
- Idempotency keys for preventing duplicate charges
- Ash actions triggered by webhook events
- Oban jobs for handling webhook processing asynchronously

**Code Organization**:
- Service: `lib/pilates_on_phx/payments/checkout_service.ex`
- Webhook: `lib/pilates_on_phx_web/controllers/stripe_webhook_controller.ex`
- Transactions: `lib/pilates_on_phx/payments/resources/transaction.ex`
- Subscriptions: `lib/pilates_on_phx/payments/resources/subscription.ex`

**Security Considerations**:
- Verify webhook signatures using Stripe webhook secret
- Never store credit card details (PCI compliance)
- Use HTTPS for all Stripe communications
- Audit log all payment transactions
- Rate limiting on checkout endpoints
- Environment variables for Stripe API keys (separate for test/prod)

**Performance Considerations**:
- Process webhooks asynchronously using Oban
- Webhook endpoint must respond within 30 seconds (Stripe timeout)
- Index on `transactions(client_id, created_at)`
- Cache Stripe customer IDs to avoid repeated API calls

**Testing Strategy**:
- Use Stripe test mode for all development and testing
- Test webhook handling with Stripe CLI
- Test payment success and failure scenarios
- Test subscription lifecycle (create, renew, cancel)
- Integration test full checkout flow
- Test idempotency (duplicate webhook handling)

**Supporting Documentation**:
- Stripe API documentation
- Stripity Stripe hex docs: https://hexdocs.pm/stripity_stripe/
- Stripe webhook testing guide
- CLAUDE.md lines 145-175: External integrations

**Dependencies**: PHX-5 (Package), External service (Stripe)

**Estimate**: 13 story points

---

### PHX-22: Resend/SendGrid Email Service Integration

**Title**: Integrate transactional email service for reliable email delivery

**User Story**:  
As a studio owner, I need reliable email delivery for booking confirmations and reminders, so that my clients stay informed about their classes.

**Description**:  
Integrate Resend or SendGrid for transactional email delivery with template management, delivery tracking, and bounce handling. Replaces local SMTP for production email sending.

**Use Cases**:

```gherkin
Scenario: [Happy Path] Send booking confirmation email
  Given a client books a class
  When the booking is confirmed
  Then a booking confirmation email is queued
  And the email is sent via Resend/SendGrid
  And the email includes class details and cancellation policy
  And delivery is tracked in the database
  And the client receives the email within 30 seconds

Scenario: [Happy Path] Track email delivery status
  Given an email was sent to a client
  When I view the email delivery logs
  Then I see the delivery status (delivered, bounced, opened, clicked)
  And I see the timestamp of each event
  And I can view the full email content

Scenario: [Happy Path] Use branded email templates
  Given the studio has custom branding (logo, colors)
  When any email is sent
  Then the email uses the branded template
  And includes the studio logo
  And uses studio colors and fonts
  And includes studio contact information in footer

Scenario: [Edge Case] Handle email bounce
  Given a client's email address is invalid
  When an email is sent to that address
  Then the email provider returns a bounce event
  And the bounce is recorded in the database
  And the client's email is marked as invalid
  And an admin alert is created for manual follow-up

Scenario: [Edge Case] Handle rate limiting
  Given 1000 emails need to be sent simultaneously
  When the email sending job runs
  Then emails are sent in batches respecting rate limits
  And the job does not exceed provider's rate limit
  And all emails are eventually delivered without errors

Scenario: [Error Case] Handle provider outage
  Given Resend/SendGrid API is unavailable
  When an email is queued for sending
  Then the job retries with exponential backoff
  And after max retries, an admin alert is created
  And the email is marked as failed for manual intervention
```

**Acceptance Criteria**:

1. Integration with Resend or SendGrid API
2. All transactional emails routed through email service
3. Email templates support HTML and plain text versions
4. Delivery tracking for sent, delivered, bounced, opened, clicked
5. Bounce handling marks invalid emails and alerts admins
6. Rate limiting respects provider limits (avoid throttling)
7. Retry logic for failed sends (max 3 attempts)
8. Admin dashboard shows email delivery metrics
9. Branded templates with studio logo and colors
10. Webhook handler for delivery status events

**Technical Implementation Details**:

**Reusable Modules/Classes**:
- Hex package: `:resend` or `:sendgrid` (depending on choice)
- Ash resource: `PilatesOnPhx.Communications.EmailLog`
- Mailer adapter: `PilatesOnPhx.Mailer.ResendAdapter`
- Webhook controller: `PilatesOnPhxWeb.EmailWebhookController`
- Template engine: Phoenix.View with HEEx templates

**Implementation Patterns**:
- Phoenix.Swoosh for email abstraction layer
- Custom Swoosh adapter for Resend/SendGrid
- Webhook signature verification for delivery events
- Oban for email queuing and retry logic
- Template inheritance for branded layouts
- Attachment support for PDFs (receipts, reports)

**Code Organization**:
- Mailer: `lib/pilates_on_phx/mailer.ex`
- Adapter: `lib/pilates_on_phx/mailer/resend_adapter.ex`
- Templates: `lib/pilates_on_phx_web/emails/`
- Webhook: `lib/pilates_on_phx_web/controllers/email_webhook_controller.ex`
- Logs: `lib/pilates_on_phx/communications/resources/email_log.ex`

**Security Considerations**:
- Store API keys in environment variables
- Verify webhook signatures
- Sanitize email content to prevent injection
- Rate limiting on email sending
- Audit log all email sends

**Performance Considerations**:
- Batch email sends (100 at a time)
- Respect provider rate limits (Resend: 10 req/sec, SendGrid: varies by plan)
- Async email sending via Oban
- Cache email templates for faster rendering
- Index on `email_logs(sent_at, status)`

**Testing Strategy**:
- Use provider test mode for development
- Test email delivery with test email addresses
- Test bounce and complaint handling
- Test template rendering with various data
- Integration test full email workflow
- Test webhook signature verification

**Supporting Documentation**:
- Resend documentation: https://resend.com/docs
- SendGrid documentation: https://docs.sendgrid.com/
- Phoenix Swoosh: https://hexdocs.pm/swoosh/
- CLAUDE.md lines 145-175: External integrations

**Dependencies**: All features sending emails (PHX-15, PHX-16, PHX-18, etc.)

**Estimate**: 8 story points

---

### PHX-23: Twilio SMS Integration

**Title**: Integrate Twilio for SMS notifications and reminders

**User Story**:  
As a client, I can receive SMS notifications for class reminders and important updates, so that I stay informed via my preferred communication channel.

**Description**:  
Integrate Twilio for sending SMS notifications including class reminders, booking confirmations, and waitlist promotions. Includes opt-in/opt-out management and delivery tracking.

**Use Cases**:

```gherkin
Scenario: [Happy Path] Send class reminder SMS
  Given a client has opted into SMS notifications
  And the client has a class in 2 hours
  When the reminder job runs
  Then an SMS is sent to the client's mobile number
  And the SMS contains class time, instructor, and location
  And the SMS includes a link to view booking details
  And delivery is tracked in the database

Scenario: [Happy Path] Opt-in to SMS notifications
  Given I am editing my profile
  When I enter my mobile number
  And I check "Enable SMS notifications"
  And I save my preferences
  Then I receive an opt-in confirmation SMS
  And the SMS includes instructions to reply STOP to opt-out
  And my preferences are saved

Scenario: [Happy Path] Opt-out via SMS reply
  Given I have SMS notifications enabled
  When I reply "STOP" to any SMS from the system
  Then my SMS notifications are disabled
  And I receive a confirmation SMS
  And future SMS messages are not sent to me

Scenario: [Edge Case] Handle invalid phone number
  Given I enter an invalid phone number "123"
  When I try to enable SMS notifications
  Then I see an error "Invalid phone number format"
  And SMS notifications are not enabled
  And I can correct the phone number

Scenario: [Edge Case] Handle undelivered SMS
  Given an SMS is sent to a client
  When Twilio reports delivery failure (invalid number)
  Then the failure is recorded in the database
  And the client's phone number is marked as invalid
  And an admin alert is created
  And the client receives an email notification instead

Scenario: [Error Case] Handle Twilio API outage
  Given Twilio API is unavailable
  When an SMS is queued for sending
  Then the job retries with exponential backoff
  And after max retries, fallback to email notification
  And an admin alert is created
```

**Acceptance Criteria**:

1. Integration with Twilio REST API
2. SMS sending for reminders, confirmations, and alerts
3. Opt-in/opt-out management via profile settings
4. STOP/START keyword handling for compliance
5. Phone number validation before enabling SMS
6. Delivery tracking for sent, delivered, failed
7. Failed SMS fallback to email notification
8. Rate limiting to respect Twilio limits and prevent abuse
9. Admin dashboard shows SMS delivery metrics
10. Cost tracking for SMS sends (Twilio charges per message)

**Technical Implementation Details**:

**Reusable Modules/Classes**:
- Hex package: `:ex_twilio` for Twilio API
- Ash resource: `PilatesOnPhx.Communications.SmsLog`
- SMS sender: `PilatesOnPhx.Notifications.SmsSender`
- Webhook controller: `PilatesOnPhxWeb.TwilioWebhookController`
- Phone validator: `:ex_phone_number` for validation

**Implementation Patterns**:
- Twilio REST API for sending SMS
- Twilio webhooks for delivery status and STOP/START replies
- Oban for SMS queuing and retry logic
- Phone number normalization to E.164 format
- Message templates with variable interpolation
- Webhook signature verification for security

**Code Organization**:
- Sender: `lib/pilates_on_phx/notifications/sms_sender.ex`
- Webhook: `lib/pilates_on_phx_web/controllers/twilio_webhook_controller.ex`
- Logs: `lib/pilates_on_phx/communications/resources/sms_log.ex`
- Validator: `lib/pilates_on_phx/validators/phone_number_validator.ex`

**Security Considerations**:
- Store Twilio credentials in environment variables
- Verify webhook signatures from Twilio
- Rate limiting: Max 10 SMS per client per day
- Audit log all SMS sends
- Comply with TCPA and GDPR for SMS marketing

**Performance Considerations**:
- Respect Twilio rate limits (varies by account)
- Batch SMS sends if possible
- Async sending via Oban
- Index on `sms_logs(sent_at, status)`
- Track costs per SMS for budgeting

**Testing Strategy**:
- Use Twilio test credentials for development
- Test SMS delivery to test phone numbers
- Test STOP/START keyword handling
- Test phone number validation
- Integration test full SMS workflow
- Test webhook signature verification
- Test fallback to email on SMS failure

**Supporting Documentation**:
- Twilio documentation: https://www.twilio.com/docs/
- Ex Twilio hex docs: https://hexdocs.pm/ex_twilio/
- TCPA compliance guide
- CLAUDE.md lines 145-175: External integrations

**Dependencies**: PHX-15 (Reminders), PHX-16 (Waitlist), PHX-14 (Profile)

**Estimate**: 8 story points

---

### PHX-24: Calendar Integration (iCal Export)

**Title**: Implement iCal export for adding classes to personal calendars

**User Story**:  
As a client, I can export my booked classes to my calendar app (Google Calendar, Apple Calendar), so that I have all my commitments in one place.

**Description**:  
Build iCal (.ics) export functionality that generates downloadable calendar files for individual bookings and full booking schedules. Includes automatic updates when bookings change.

**Use Cases**:

```gherkin
Scenario: [Happy Path] Export single booking to calendar
  Given I have a confirmed booking for a class
  When I click "Add to Calendar" on the booking
  Then an .ics file is generated and downloaded
  And the file includes class name, date, time, location
  And the file includes instructor name in description
  And the file includes studio address for map integration
  And I can open the file in my calendar app

Scenario: [Happy Path] Subscribe to booking calendar feed
  Given I am viewing my bookings dashboard
  When I click "Subscribe to Calendar"
  Then I receive a unique calendar feed URL
  And the URL can be added to Google Calendar or Apple Calendar
  And the feed automatically updates when I book/cancel classes
  And I see all my future bookings in the calendar app

Scenario: [Happy Path] Calendar event includes reminders
  Given I export a class booking to calendar
  When I open the .ics file
  Then the event includes a 2-hour reminder
  And the event includes a 30-minute reminder
  And I can modify reminders in my calendar app

Scenario: [Edge Case] Handle cancelled booking in feed
  Given I have subscribed to the booking calendar feed
  And I had a booking for tomorrow
  When I cancel the booking
  Then the calendar feed is updated
  And the event is removed from my calendar app (on next sync)

Scenario: [Edge Case] Generate calendar for recurring bookings
  Given I have a weekly recurring booking every Monday at 10 AM
  When I export to calendar
  Then a recurring event is created in the .ics file
  And the recurrence rule matches my booking pattern
  And the event repeats every Monday

Scenario: [Error Case] Handle invalid calendar feed URL
  Given I have a subscribed calendar feed
  When the feed URL is accessed with invalid auth token
  Then access is denied
  And no booking data is exposed
  And an error message is returned
```

**Acceptance Criteria**:

1. Single booking export generates valid .ics file
2. Full schedule export includes all upcoming bookings
3. Calendar feed URL (webcal://) for auto-updating subscription
4. Feed updates automatically when bookings added/cancelled
5. Events include: class name, date/time, location, instructor, description
6. Events include reminders (2-hour, 30-minute before)
7. Feed URL is unique per client with authentication token
8. Cancelled bookings are removed from feed
9. Calendar export works with Google Calendar, Apple Calendar, Outlook
10. Admin can revoke calendar feed access if needed

**Technical Implementation Details**:

**Reusable Modules/Classes**:
- Hex package: `:icalendar` for .ics generation
- Calendar service: `PilatesOnPhx.Calendar.IcalService`
- Feed controller: `PilatesOnPhxWeb.CalendarFeedController`
- Ash calculation: `Booking.to_ical_event`
- Token generation for feed authentication

**Implementation Patterns**:
- Generate .ics files using `:icalendar` library
- Unique feed URLs with authentication tokens
- Phoenix controller for serving calendar feeds
- Cache feed data with 1-hour TTL
- PubSub broadcast for feed updates
- Secure token generation for feed URLs

**Code Organization**:
- Service: `lib/pilates_on_phx/calendar/ical_service.ex`
- Controller: `lib/pilates_on_phx_web/controllers/calendar_feed_controller.ex`
- Token: `lib/pilates_on_phx/calendar/feed_token.ex`

**Security Considerations**:
- Unique authentication tokens for calendar feed URLs
- Token expiration (1 year, renewable)
- Rate limiting on feed access (max 60 requests/hour)
- Validate token before serving feed
- Revocation mechanism for compromised tokens
- Audit log feed access

**Performance Considerations**:
- Cache generated .ics files for 1 hour
- Paginate large booking lists (limit to next 90 days)
- Index on `bookings(client_id, start_time, status)`
- Serve feeds via CDN for global access
- Set appropriate HTTP cache headers

**Testing Strategy**:
- Test .ics file generation and validity
- Test calendar feed updates when bookings change
- Test token authentication and authorization
- Test compatibility with major calendar apps
- Integration test full calendar export workflow
- Test revocation and token expiry

**Supporting Documentation**:
- iCalendar specification (RFC 5545)
- `:icalendar` hex docs: https://hexdocs.pm/icalendar/
- Calendar app integration guides
- CLAUDE.md lines 145-175: External integrations

**Dependencies**: PHX-4 (Booking), PHX-3 (Client)

**Estimate**: 8 story points

---

### PHX-25: Analytics Dashboard & Reporting

**Title**: Build comprehensive analytics dashboard with real-time metrics and custom reports

**User Story**:  
As a studio owner, I can view detailed analytics and generate custom reports, so that I can understand business trends and make data-driven decisions.

**Description**:  
Create an advanced analytics dashboard using LiveView with interactive charts, real-time metrics, and custom report generation. Leverages Ash aggregates and calculations for efficient data analysis.

**Use Cases**:

```gherkin
Scenario: [Happy Path] View revenue trends chart
  Given I am viewing the analytics dashboard
  When I select "Revenue" metric and "Last 3 Months" date range
  Then I see a line chart showing daily revenue for the past 3 months
  And I can hover over data points to see exact values
  And I can toggle between daily, weekly, and monthly aggregation
  And I can export the chart as PNG or CSV

Scenario: [Happy Path] View class utilization heatmap
  Given I am viewing the analytics dashboard
  When I select "Class Utilization" report
  Then I see a heatmap showing capacity filled by day and time
  And cells are color-coded: green (80%+ full), yellow (50-80%), red (<50%)
  And I can click a cell to see classes for that time slot
  And I can identify optimal scheduling times

Scenario: [Happy Path] Generate custom client retention report
  Given I am viewing the analytics dashboard
  When I click "Custom Reports" and select "Client Retention"
  And I select date range "Last 12 Months"
  Then I see a report showing:
    | Metric | Description |
    | New Clients | Count of clients who joined |
    | Returning Clients | Clients with 2+ bookings |
    | Churned Clients | Clients with no bookings in 90 days |
    | Retention Rate | Percentage of returning clients |
  And I can export the report as PDF or CSV

Scenario: [Edge Case] View analytics for multiple studios
  Given I own 3 studio locations
  When I view the analytics dashboard
  Then I see aggregated metrics across all studios
  And I can filter to view individual studio analytics
  And I can compare studios side-by-side

Scenario: [Edge Case] Handle large dataset performance
  Given I request a report with 2 years of data
  When the report is generated
  Then I see a loading indicator
  And the report is generated asynchronously
  And I receive an email when the report is ready
  And I can download the report from the dashboard

Scenario: [Error Case] Handle metric calculation failure
  Given I request a complex custom report
  When the calculation times out after 30 seconds
  Then I see an error message "Report generation timed out"
  And I am prompted to select a smaller date range
  And I can retry with adjusted parameters
```

**Acceptance Criteria**:

1. Dashboard displays key metrics: revenue, bookings, attendance, utilization
2. Interactive charts support zoom, pan, and export (PNG, CSV)
3. Date range selector with presets (Last 7 Days, Last Month, Custom)
4. Real-time metrics update via PubSub
5. Custom report builder with metric selection and filters
6. Reports can be scheduled for automated generation (daily, weekly, monthly)
7. Export functionality for all charts and reports (PDF, CSV, Excel)
8. Multi-studio comparison views
9. Client segmentation reports (new, returning, at-risk, churned)
10. Performance optimizations for large datasets (async generation)

**Technical Implementation Details**:

**Reusable Modules/Classes**:
- Analytics domain: `PilatesOnPhx.Analytics`
- Chart library: `:contex` or LiveView native charting
- Report generator: `PilatesOnPhx.Analytics.ReportBuilder`
- Ash aggregates for efficient metric calculations
- LiveView for interactive dashboard
- Oban for async report generation

**Implementation Patterns**:
- LiveView async assigns for loading metrics
- Ash aggregates for counts, sums, averages
- Database materialized views for complex metrics
- LiveView streams for report data
- PubSub for real-time metric updates
- CSV/PDF export using Elixir libraries

**Code Organization**:
- LiveView: `lib/pilates_on_phx_web/live/analytics_live/dashboard.ex`
- Domain: `lib/pilates_on_phx/analytics/`
- Reports: `lib/pilates_on_phx/analytics/report_builder.ex`
- Charts: `lib/pilates_on_phx_web/components/charts/`

**Security Considerations**:
- Authorization: Only owners/managers can access analytics
- Multi-tenant: Scope all queries to user's studios
- Rate limiting on report generation
- Audit log report access and exports

**Performance Considerations**:
- Use database indexes for all metric queries
- Cache metrics with 5-minute TTL
- Async report generation for large datasets
- Database materialized views for complex aggregations
- Paginate large result sets
- Background job for scheduled reports

**Testing Strategy**:
- Test metric calculations with known datasets
- Test chart rendering and interactivity
- Test export functionality (CSV, PDF)
- Performance test with large datasets
- Integration test full analytics workflow
- Test authorization for multi-studio scenarios

**Supporting Documentation**:
- Contex documentation: https://hexdocs.pm/contex/
- Ash aggregates and calculations
- LiveView async assigns patterns
- CLAUDE.md lines 145-175: Analytics implementation

**Dependencies**: All Sprint 1-3 resources

**Estimate**: 13 story points

---

### PHX-26: Mobile App Support (PWA/Capacitor)

**Title**: Implement Progressive Web App (PWA) features and Capacitor setup for mobile apps

**User Story**:  
As a client, I can install the app on my mobile device and receive push notifications, so that I have a native-like mobile experience.

**Description**:  
Transform the Phoenix LiveView app into a Progressive Web App (PWA) with offline support, push notifications, and app installation. Optionally set up Capacitor for native iOS/Android builds.

**Use Cases**:

```gherkin
Scenario: [Happy Path] Install PWA on mobile device
  Given I am visiting the app on my mobile browser
  When I see the "Add to Home Screen" prompt
  And I click "Install"
  Then the app is installed as a standalone app
  And I see the app icon on my home screen
  And I can launch the app without browser UI

Scenario: [Happy Path] Receive push notification for class reminder
  Given I have the PWA installed
  And I have enabled push notifications
  When a class reminder is triggered
  Then I receive a push notification on my device
  And the notification shows class name and time
  And tapping the notification opens the app to booking details

Scenario: [Happy Path] Use app offline
  Given I have the PWA installed
  And I have loaded the app while online
  When I lose internet connection
  Then I can still view my upcoming bookings (cached)
  And I can still view class details
  And I see an indicator that I am offline
  And actions requiring network show "Offline" message

Scenario: [Edge Case] Sync data when back online
  Given I was using the app offline
  And I attempted to book a class (failed due to offline)
  When I regain internet connection
  Then the app automatically syncs
  And I see an option to retry my booking
  And my bookings list is updated with latest data

Scenario: [Edge Case] Handle push notification permission denied
  Given I am using the PWA
  When I deny push notification permission
  Then the app respects my choice
  And I do not see repeated permission prompts
  And I can still use all other app features
  And I can enable notifications later in settings

Scenario: [Error Case] Handle service worker update
  Given I have the PWA installed with version 1.0
  And version 1.1 is deployed
  When the service worker detects an update
  Then I see a "Update Available" message
  And I can click "Update Now" to reload the app
  And the app updates to version 1.1 seamlessly
```

**Acceptance Criteria**:

1. PWA manifest configured with app icons, theme colors, name
2. Service worker provides offline support for key pages
3. Push notification support for class reminders and updates
4. App installable on iOS, Android, and desktop
5. Offline indicator shows network status
6. Background sync retries failed actions when online
7. Service worker update prompt for new versions
8. App shell caching for fast loading
9. Capacitor setup for optional native iOS/Android builds
10. Push notification permissions handled gracefully

**Technical Implementation Details**:

**Reusable Modules/Classes**:
- Phoenix PWA generator or manual manifest.json
- Service worker: `assets/js/sw.js`
- Push notification: Web Push API and Phoenix Channels
- Capacitor: `@capacitor/core`, `@capacitor/ios`, `@capacitor/android`
- IndexedDB for offline data storage

**Implementation Patterns**:
- Service worker with caching strategies (network first, cache first)
- Phoenix PubSub for push notification delivery
- Background sync for queued actions
- App manifest for PWA installability
- Capacitor plugins for native features (Camera, Notifications)

**Code Organization**:
- Manifest: `priv/static/manifest.json`
- Service worker: `assets/js/sw.js`
- Push notifications: `lib/pilates_on_phx_web/channels/push_notification_channel.ex`
- Capacitor config: `capacitor.config.ts`

**Security Considerations**:
- HTTPS required for PWA and push notifications
- Validate push notification subscriptions
- Secure service worker caching (no sensitive data cached)
- Push notification permissions follow OS guidelines

**Performance Considerations**:
- Service worker caching reduces load times
- App shell loads instantly from cache
- Background sync prevents data loss
- Optimize asset sizes for mobile networks

**Testing Strategy**:
- Test PWA installability on iOS, Android, desktop
- Test offline functionality and caching
- Test push notifications on various devices
- Test service worker update mechanism
- Integration test full PWA workflow
- Test Capacitor build for iOS/Android

**Supporting Documentation**:
- PWA documentation: https://web.dev/progressive-web-apps/
- Service worker guide
- Capacitor documentation: https://capacitorjs.com/
- CLAUDE.md lines 145-175: Mobile app support

**Dependencies**: All Sprint 1-3 features

**Estimate**: 13 story points

---

## Sprint Summary

### Sprint 2: LiveView Interfaces & User Workflows (6 issues, 50 story points)
- PHX-9: Class Browse & Search Interface (5 pts)
- PHX-10: Class Booking Workflow with Real-Time Validation (8 pts)
- PHX-11: Client Dashboard with Bookings & Credits (8 pts)
- PHX-12: Instructor Dashboard with Class Management (8 pts)
- PHX-13: Owner/Admin Dashboard with Analytics (13 pts)
- PHX-14: User Profile Management (8 pts)

### Sprint 3: Background Jobs & Automations (6 issues, 68 story points)
- PHX-15: Class Reminder Notification System (13 pts)
- PHX-16: Waitlist Promotion Automation (13 pts)
- PHX-17: Recurring Class Generation (13 pts)
- PHX-18: Package Expiration Warnings (8 pts)
- PHX-19: Attendance Tracking Automation (8 pts)
- PHX-20: Report Generation System (13 pts)

### Sprint 4: Integrations & Advanced Features (6 issues, 63 story points)
- PHX-21: Stripe Payment Integration (13 pts)
- PHX-22: Resend/SendGrid Email Service Integration (8 pts)
- PHX-23: Twilio SMS Integration (8 pts)
- PHX-24: Calendar Integration (iCal Export) (8 pts)
- PHX-25: Analytics Dashboard & Reporting (13 pts)
- PHX-26: Mobile App Support (PWA/Capacitor) (13 pts)

**Total**: 18 issues, 181 story points

---

## Next Steps for Linear Issue Creation

For each issue above:

1. **Create Linear Issue** with title and description
2. **Assign to Project**: Sprint 2, Sprint 3, or Sprint 4 project
3. **Set Priority**: Based on dependencies and business value
4. **Add Labels**: "feature", "liveview", "background-job", "integration", etc.
5. **Set Dependencies**: Link to prerequisite Sprint 1 issues
6. **Add to Milestone**: Group related features
7. **Team Assignment**: AltBuild-PHX team

### Recommended Issue Metadata

**Projects to Create**:
1. Sprint 2 - LiveView Interfaces & User Workflows
2. Sprint 3 - Background Jobs & Automations
3. Sprint 4 - Integrations & Advanced Features

**Common Labels**:
- feature
- enhancement
- liveview
- background-job
- integration
- payment
- notification
- analytics
- mobile

**Priorities**:
- Urgent: PHX-9, PHX-10 (core booking flow)
- High: PHX-11, PHX-12, PHX-15, PHX-21 (essential features)
- Medium: PHX-13, PHX-16, PHX-17, PHX-22, PHX-23, PHX-25
- Low: PHX-14, PHX-18, PHX-19, PHX-20, PHX-24, PHX-26 (nice-to-have)

---

## Technology Implementation Notes

### Phoenix/Elixir/Ash Advantages Utilized

1. **LiveView for Real-Time Interfaces**: All UI features use LiveView for instant updates without custom JavaScript
2. **Oban for Background Jobs**: Reliable job processing with built-in retry, scheduling, and monitoring
3. **Ash Framework**: Declarative actions, calculations, aggregates, and policies simplify business logic
4. **Phoenix PubSub**: Real-time broadcasts for availability updates, roster changes, and analytics
5. **Ash Atomic Actions**: Transaction safety for complex multi-resource operations
6. **LiveView Streams**: Efficient rendering of large collections without memory issues

### External Services

- **Stripe**: Payment processing (PCI-compliant)
- **Resend/SendGrid**: Transactional email delivery
- **Twilio**: SMS notifications
- **Cloud Storage**: S3 for profile photos and report PDFs

### Development Standards

All features must:
- Follow Phoenix 1.8 and Ash 3.7+ best practices
- Maintain 85%+ test coverage on business logic
- Implement authorization policies for multi-tenant isolation
- Use Oban for all background processing
- Leverage LiveView for real-time interfaces
- Document implementation patterns

---

## Appendix: Requirements Source Analysis

### NextJS Team (Wlstory) - Requirements Extraction Needed

**Action Required**: Fetch Linear issues from Wlstory team using pagination (limit 50 per request) to identify:
- React component patterns → Adapt to LiveView components
- REST API endpoints → Adapt to Ash actions
- State management → Adapt to LiveView assigns
- Client-side validation → Adapt to LiveView changesets

### Rails Team (AltBuild-Rails) - Requirements Extraction Needed

**Action Required**: Fetch Linear issues from AltBuild-Rails team using pagination to identify:
- ActiveRecord models → Adapt to Ash resources
- Controller actions → Adapt to Ash actions + LiveView
- Background jobs → Adapt to Oban workers
- Validations → Adapt to Ash validations

**Note**: This roadmap document serves as a comprehensive specification for all Sprint 2, 3, and 4 features. Each issue above should be created in Linear under the AltBuild-PHX team with appropriate projects, priorities, and metadata.

---

**Document Version**: 1.0  
**Last Updated**: 2025-11-10  
**Author**: catalio-product-manager agent  
**Review Status**: Ready for Linear issue creation
