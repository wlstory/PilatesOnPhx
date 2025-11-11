# Sprint 3, 4, and Backlog Issues - Complete Specifications

This document contains all remaining user stories for Sprints 3-4 and backlog items with complete Phoenix/Elixir/Ash implementation details.

---

## Sprint 3 - Automation & Background Jobs

**Project Created**: Sprint 3 - Automation & Background Jobs (ID: ababcd9e-fe4a-4f88-a68a-a8a63a09043c)

### Epic PHX-34: Email & SMS Reminder System

**Project**: Sprint 3 - Automation & Background Jobs
**Priority**: Urgent (1)
**Labels**: epic, automation, notifications, oban, sprint-3

#### Epic Overview

Implement automated email and SMS reminder system for upcoming classes to reduce no-shows and improve client engagement. Reminders sent at 24 hours and 2 hours before class start time.

**Original Source**: WLS-99 (Scheduled Reports), WLS-116 (Gap Analysis - Reminder System)

#### Problem Statement

No-show rates average 15-20% without reminders. Automated reminders reduce no-shows to <5%, significantly improving studio revenue and class planning. Manual reminder calls are time-consuming and inconsistent.

#### Scope

**Reminder Types**:
- 24-hour advance reminder (email + SMS)
- 2-hour advance reminder (SMS only)
- Booking confirmation (immediate)
- Waitlist promotion notification
- Class cancellation notice

**Client Preferences**:
- Opt-in/opt-out per channel
- Preferred reminder times
- Blackout hours (e.g., no SMS 10pm-8am)

**Delivery Infrastructure**:
- Email via Resend or SendGrid
- SMS via Twilio
- Retry logic for failed sends
- Delivery tracking and logging

#### Use Cases

```gherkin
Scenario: [Happy Path] 24-hour reminder sent for upcoming class
  Given a client has a confirmed booking for "Reformer Pilates" tomorrow at 10am
  When the Oban cron job runs at 10am today
  Then system finds all bookings 24 hours in future
  And queues reminder job for this booking
  And job sends email reminder to client
  And job sends SMS reminder to client's phone
  And delivery is logged with timestamps
  And client receives both email and SMS

Scenario: [Happy Path] 2-hour reminder sent
  Given a client has a booking for class starting at 2pm
  When the current time is 12:00pm (2 hours before)
  Then system queues 2-hour reminder job
  And SMS reminder is sent (no email)
  And delivery is logged

Scenario: [Edge Case] Client has opted out of SMS
  Given a client has booking tomorrow at 10am
  And client preferences show sms_reminders: false
  When 24-hour reminder job runs
  Then only email reminder is sent
  And SMS is skipped
  And log shows "SMS skipped - client preference"

Scenario: [Edge Case] Reminder during blackout hours
  Given client has blackout hours 10pm-8am
  And booking is at 7am tomorrow (24h reminder would be 7am today)
  When reminder job runs at 7am
  Then delivery is delayed until 8am (blackout end)
  And reminder still sent but respecting preferences

Scenario: [Error Case] Email delivery fails
  Given reminder job attempts to send email
  When email service returns error (5xx)
  Then job is retried (max 3 attempts)
  And each attempt is logged
  And after 3 failures, admin is notified
  And client shows warning in dashboard
```

#### Phoenix/Elixir/Ash Implementation

**Domain**: Bookings

**Oban Workers**:

```elixir
# lib/pilates_on_phx/bookings/workers/send_class_reminders.ex
defmodule PilatesOnPhx.Bookings.Workers.SendClassReminders do
  use Oban.Worker,
    queue: :reminders,
    max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"reminder_type" => type}}) do
    case type do
      "24_hour" -> send_24_hour_reminders()
      "2_hour" -> send_2_hour_reminders()
    end
  end

  defp send_24_hour_reminders do
    # Find all bookings 24 hours in future
    target_time = DateTime.add(DateTime.utc_now(), 24, :hour)

    bookings =
      PilatesOnPhx.Bookings.Booking
      |> Ash.Query.filter(status == :confirmed)
      |> Ash.Query.load([:client, :class_session])
      |> Ash.Query.filter(
        class_session.scheduled_at >= ^DateTime.add(target_time, -30, :minute) and
        class_session.scheduled_at <= ^DateTime.add(target_time, 30, :minute)
      )
      |> PilatesOnPhx.Bookings.read!()

    # Queue individual reminder jobs
    Enum.each(bookings, fn booking ->
      %{booking_id: booking.id, type: "24_hour"}
      |> SendReminderJob.new()
      |> Oban.insert()
    end)

    {:ok, "Queued #{length(bookings)} 24-hour reminders"}
  end
end

# lib/pilates_on_phx/bookings/workers/send_reminder_job.ex
defmodule PilatesOnPhx.Bookings.Workers.SendReminderJob do
  use Oban.Worker,
    queue: :reminders,
    max_attempts: 3

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"booking_id" => booking_id, "type" => type}}) do
    booking = get_booking_with_details(booking_id)
    client = booking.client

    # Check client preferences
    send_email? = client.preferences["email_reminders"] != false
    send_sms? = client.preferences["sms_reminders"] != false

    # Send email
    if send_email? do
      case send_email_reminder(booking, type) do
        {:ok, _} -> log_delivery(booking, :email, :success)
        {:error, reason} -> log_delivery(booking, :email, :failed, reason)
      end
    end

    # Send SMS
    if send_sms? and not in_blackout_hours?(client) do
      case send_sms_reminder(booking, type) do
        {:ok, _} -> log_delivery(booking, :sms, :success)
        {:error, reason} -> log_delivery(booking, :sms, :failed, reason)
      end
    end

    :ok
  end

  defp send_email_reminder(booking, type) do
    PilatesOnPhx.Email.ClassReminderEmail.send(
      to: booking.client.user.email,
      class_name: booking.class_session.class_type.name,
      class_time: booking.class_session.scheduled_at,
      instructor: booking.class_session.instructor.name,
      type: type
    )
  end

  defp send_sms_reminder(booking, type) do
    PilatesOnPhx.SMS.TwilioService.send_sms(
      to: booking.client.phone,
      body: """
      Hi #{booking.client.first_name}! Reminder: You have #{booking.class_session.class_type.name}
      #{format_time_until(booking.class_session.scheduled_at)} at #{format_time(booking.class_session.scheduled_at)}.
      See you there!
      """
    )
  end
end
```

**Cron Configuration** (Oban.Pro or custom):

```elixir
# config/config.exs
config :pilates_on_phx, Oban,
  repo: PilatesOnPhx.Repo,
  plugins: [
    {Oban.Plugins.Cron,
      crontab: [
        # Every hour, check for 24-hour reminders
        {"0 * * * *", PilatesOnPhx.Bookings.Workers.SendClassReminders,
          args: %{reminder_type: "24_hour"}},

        # Every 30 minutes, check for 2-hour reminders
        {"*/30 * * * *", PilatesOnPhx.Bookings.Workers.SendClassReminders,
          args: %{reminder_type: "2_hour"}}
      ]
    }
  ],
  queues: [default: 10, reminders: 20, mailers: 10]
```

**Email Service Integration** (Resend):

```elixir
# lib/pilates_on_phx/email/class_reminder_email.ex
defmodule PilatesOnPhx.Email.ClassReminderEmail do
  use Phoenix.Swoosh,
    template_root: "lib/pilates_on_phx_web/templates/email",
    template_path: "reminders"

  def send(assigns) do
    new()
    |> to(assigns.to)
    |> from({"Studio Name", "noreply@studio.com"})
    |> subject(subject_for_type(assigns.type))
    |> render_body("class_reminder.html", assigns)
    |> PilatesOnPhx.Mailer.deliver()
  end

  defp subject_for_type("24_hour"), do: "Class Reminder: Tomorrow at #{time}"
  defp subject_for_type("2_hour"), do: "Starting Soon: Class in 2 hours"
end
```

**SMS Service Integration** (Twilio):

```elixir
# lib/pilates_on_phx/sms/twilio_service.ex
defmodule PilatesOnPhx.SMS.TwilioService do
  def send_sms(to: phone, body: message) do
    ExTwilio.Message.create(
      to: phone,
      from: System.get_env("TWILIO_PHONE_NUMBER"),
      body: message
    )
  end
end
```

**Reminder Delivery Log** (for tracking):

```elixir
# lib/pilates_on_phx/bookings/reminder_delivery.ex
defmodule PilatesOnPhx.Bookings.ReminderDelivery do
  use Ash.Resource,
    domain: PilatesOnPhx.Bookings,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key :id
    attribute :channel, :atom # :email, :sms
    attribute :reminder_type, :atom # :24_hour, :2_hour, :confirmation
    attribute :status, :atom # :success, :failed, :skipped
    attribute :error_message, :string
    attribute :sent_at, :utc_datetime
    timestamps()
  end

  relationships do
    belongs_to :booking, PilatesOnPhx.Bookings.Booking
  end
end
```

#### User Stories (Children)

- PHX-35: Configure Oban for Background Jobs
- PHX-36: Email Reminder Service Integration (Resend)
- PHX-37: SMS Reminder Service Integration (Twilio)
- PHX-38: 24-Hour Class Reminder Job
- PHX-39: 2-Hour Class Reminder Job
- PHX-40: Client Reminder Preferences Management
- PHX-41: Reminder Delivery Tracking & Logging

#### Dependencies

- Sprint 2 complete (Booking workflow)
- PHX-9: Bookings Domain
- Oban installed and configured
- Email service account (Resend/SendGrid)
- Twilio account for SMS

#### Testing Strategy

- Test Oban worker execution
- Mock email/SMS services in tests
- Test cron scheduling (Oban test helpers)
- Test client preference filtering
- Test blackout hours logic
- Test retry logic for failures
- Integration test for complete flow
- 85%+ coverage on workers

#### Success Criteria

- 95%+ reminder delivery rate
- Reminders sent within 5 minutes of target time
- Zero duplicate reminders
- Client preferences respected 100%
- Failed deliveries retry correctly
- Dashboard shows delivery metrics

---

### Epic PHX-42: Scheduled Reports & Analytics

**Project**: Sprint 3 - Automation & Background Jobs
**Priority**: High (2)
**Labels**: epic, reports, analytics, oban, sprint-3

#### Epic Overview

Implement automated report generation and delivery system for studio owners and instructors. Reports include financial summaries, attendance trends, class utilization, and package sales.

**Original Source**: WLS-99 (Scheduled Reports), WLS-116 (Gap Analysis)

#### Problem Statement

Studio owners need regular insights into business performance but don't have time for manual report generation. Automated weekly/monthly reports delivered via email save hours and provide timely business intelligence.

#### Scope

**Report Types**:
1. Financial Summary (revenue, package sales, refunds)
2. Class Attendance Report (utilization, no-shows, trends)
3. Package Usage Report (redemptions, expirations, conversions)
4. Instructor Performance (classes taught, average attendance)
5. Client Retention (active clients, churn rate)

**Scheduling**:
- Daily (optional)
- Weekly (most common)
- Monthly
- Custom date ranges on demand

**Delivery**:
- Email with PDF attachment
- CSV export option
- Dashboard view
- Scheduled delivery

#### Use Cases

```gherkin
Scenario: [Happy Path] Weekly financial report generated and emailed
  Given studio owner has scheduled weekly financial report for Monday 9am
  When Oban cron job runs Monday at 9am
  Then system generates report for previous week (Mon-Sun)
  And report includes: total revenue, package sales, refunds, net revenue
  And report is formatted as PDF
  And email is sent to owner with PDF attached
  And report is saved to dashboard for later viewing

Scenario: [Happy Path] Monthly class utilization report
  Given owner has monthly report scheduled for 1st of month
  When job runs on January 1st
  Then report covers December 1-31
  And shows class capacity utilization by class type
  And shows peak hours and low-attendance times
  And recommendations for schedule optimization
  And delivered via email

Scenario: [Edge Case] Custom date range report on demand
  Given owner wants report for specific period (Dec 15 - Jan 15)
  When they request custom report from dashboard
  Then job is queued immediately
  And report generated for exact date range
  And delivered within 5 minutes
  And no scheduled reports are affected

Scenario: [Error Case] Report generation fails (database timeout)
  Given weekly report job runs
  When database query times out (large dataset)
  Then job is retried (max 2 attempts)
  And if still fails, admin is notified
  And owner receives email: "Report delayed, will retry"
  And successful retry delivers report with note
```

#### Phoenix/Elixir/Ash Implementation

**Domain**: Studios (reporting is studio-level)

**Report Resources**:

```elixir
# lib/pilates_on_phx/studios/scheduled_report.ex
defmodule PilatesOnPhx.Studios.ScheduledReport do
  use Ash.Resource,
    domain: PilatesOnPhx.Studios,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key :id
    attribute :report_type, :atom # :financial, :attendance, :packages, :retention
    attribute :frequency, :atom # :daily, :weekly, :monthly
    attribute :schedule_day, :string # "monday", "1" (for monthly)
    attribute :schedule_time, :time # 09:00
    attribute :recipient_emails, {:array, :string}
    attribute :format, :atom # :pdf, :csv, :xlsx
    attribute :enabled, :boolean, default: true
    attribute :last_run_at, :utc_datetime
    attribute :next_run_at, :utc_datetime
    timestamps()
  end

  relationships do
    belongs_to :studio, PilatesOnPhx.Studios.Studio
  end

  actions do
    create :schedule do
      accept [:report_type, :frequency, :schedule_day, :schedule_time, :recipient_emails, :format]
      change calculate_next_run()
    end

    update :execute do
      change generate_and_send_report()
      change set_attribute(:last_run_at, &DateTime.utc_now/0)
      change calculate_next_run()
    end
  end
end
```

**Oban Workers**:

```elixir
# lib/pilates_on_phx/studios/workers/generate_scheduled_reports.ex
defmodule PilatesOnPhx.Studios.Workers.GenerateScheduledReports do
  use Oban.Worker,
    queue: :reports,
    max_attempts: 2

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    # Find all scheduled reports due now
    now = DateTime.utc_now()

    due_reports =
      PilatesOnPhx.Studios.ScheduledReport
      |> Ash.Query.filter(enabled == true)
      |> Ash.Query.filter(next_run_at <= ^now)
      |> PilatesOnPhx.Studios.read!()

    # Queue individual report generation jobs
    Enum.each(due_reports, fn report ->
      %{scheduled_report_id: report.id}
      |> GenerateReportJob.new()
      |> Oban.insert()
    end)

    {:ok, "Queued #{length(due_reports)} reports"}
  end
end

# lib/pilates_on_phx/studios/workers/generate_report_job.ex
defmodule PilatesOnPhx.Studios.Workers.GenerateReportJob do
  use Oban.Worker,
    queue: :reports,
    max_attempts: 2

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"scheduled_report_id" => report_id}}) do
    report = get_scheduled_report(report_id)

    # Calculate date range
    {start_date, end_date} = calculate_date_range(report)

    # Generate report data
    data = generate_report_data(report.report_type, report.studio_id, start_date, end_date)

    # Format report (PDF/CSV)
    file_path = format_report(data, report.format, report.report_type)

    # Send email with attachment
    send_report_email(report, file_path)

    # Update last_run_at and next_run_at
    report
    |> Ash.Changeset.for_update(:execute, %{})
    |> Ash.update!()

    :ok
  end

  defp generate_report_data(:financial, studio_id, start_date, end_date) do
    # Query bookings, payments, refunds
    payments =
      PilatesOnPhx.Bookings.Payment
      |> Ash.Query.filter(studio_id == ^studio_id)
      |> Ash.Query.filter(created_at >= ^start_date and created_at <= ^end_date)
      |> PilatesOnPhx.Bookings.read!()

    total_revenue = Enum.reduce(payments, 0, fn p, acc -> acc + p.amount_cents end)
    package_sales = Enum.filter(payments, &(&1.payment_type == :package_purchase))
    refunds = Enum.filter(payments, &(&1.payment_type == :refund))

    %{
      period: "#{start_date} to #{end_date}",
      total_revenue: total_revenue,
      package_count: length(package_sales),
      refund_count: length(refunds),
      net_revenue: total_revenue - Enum.sum(Enum.map(refunds, & &1.amount_cents))
    }
  end

  defp generate_report_data(:attendance, studio_id, start_date, end_date) do
    # Query class sessions and attendance
    sessions =
      PilatesOnPhx.Classes.ClassSession
      |> Ash.Query.filter(studio_id == ^studio_id)
      |> Ash.Query.filter(scheduled_at >= ^start_date and scheduled_at <= ^end_date)
      |> Ash.Query.load([:bookings, :class_type])
      |> PilatesOnPhx.Classes.read!()

    total_sessions = length(sessions)
    total_capacity = Enum.sum(Enum.map(sessions, & &1.max_capacity))
    total_bookings = Enum.sum(Enum.map(sessions, &length(&1.bookings)))
    utilization = if total_capacity > 0, do: (total_bookings / total_capacity * 100), else: 0

    %{
      period: "#{start_date} to #{end_date}",
      total_classes: total_sessions,
      total_capacity: total_capacity,
      total_bookings: total_bookings,
      utilization_percent: Float.round(utilization, 1),
      by_class_type: group_by_class_type(sessions)
    }
  end

  defp format_report(data, :pdf, report_type) do
    # Generate PDF using PdfEx or similar
    PilatesOnPhx.Reports.PDFGenerator.generate(data, report_type)
  end

  defp format_report(data, :csv, report_type) do
    # Generate CSV
    PilatesOnPhx.Reports.CSVGenerator.generate(data, report_type)
  end

  defp send_report_email(report, file_path) do
    Enum.each(report.recipient_emails, fn email ->
      PilatesOnPhx.Email.ReportEmail.send(
        to: email,
        subject: "#{humanize(report.report_type)} Report - #{Date.utc_today()}",
        report_type: report.report_type,
        attachment: file_path
      )
    end)
  end
end
```

**Cron Configuration**:

```elixir
config :pilates_on_phx, Oban,
  plugins: [
    {Oban.Plugins.Cron,
      crontab: [
        # Every 15 minutes, check for due reports
        {"*/15 * * * *", PilatesOnPhx.Studios.Workers.GenerateScheduledReports}
      ]
    }
  ]
```

#### User Stories (Children)

- PHX-43: Scheduled Report Configuration UI
- PHX-44: Financial Summary Report Generation
- PHX-45: Class Attendance & Utilization Report
- PHX-46: Package Usage & Expiration Report
- PHX-47: PDF Report Formatting
- PHX-48: CSV Export Functionality
- PHX-49: Email Delivery with Attachments

#### Dependencies

- Sprint 2 complete
- PHX-9: Bookings Domain (for payment/package data)
- PHX-4: Classes Domain (for attendance data)
- Oban configured
- Email service configured

#### Testing Strategy

- Test report data generation (mock data)
- Test PDF generation
- Test CSV generation
- Test email delivery (mock)
- Test cron scheduling
- Test date range calculations
- Integration test for scheduled execution
- 85%+ coverage

---

### Epic PHX-50: Recurring Class Automation

**Project**: Sprint 3 - Automation & Background Jobs
**Priority**: High (2)
**Labels**: epic, automation, classes, oban, sprint-3

#### Epic Overview

Automate the generation of future class sessions from recurring schedule templates. Weekly Oban job creates class sessions 4-8 weeks in advance based on recurring patterns defined by studio owners.

**Original Source**: WLS-97 (Recurring Classes)

#### Problem Statement

Studio owners must manually create dozens of class instances weekly. Automated generation from templates ensures classes are always available for booking well in advance, improving client experience and reducing administrative burden.

#### Scope

**Auto-Generation**:
- Weekly job generates sessions 4 weeks in advance
- Uses ClassSchedule templates (recurring patterns)
- Respects instructor availability
- Checks room conflicts
- Skips holidays (studio closure dates)

**Conflict Detection**:
- Instructor double-booking prevention
- Room conflicts
- Studio closure dates
- Capacity validation

**Notifications**:
- Owners notified of generated classes
- Warnings for conflicts
- Summary email weekly

#### Use Cases

```gherkin
Scenario: [Happy Path] Weekly job generates classes from templates
  Given studio has ClassSchedule "Reformer Mon/Wed/Fri 10am"
  And pattern is weekly, days [1, 3, 5], time 10:00
  When weekly generation job runs on Sunday
  Then system generates classes for next 4 weeks
  And creates 12 class sessions (3 per week * 4 weeks)
  And all sessions have instructor, room, class type from template
  And sessions are marked as auto-generated
  And owner receives summary email

Scenario: [Edge Case] Instructor has conflict on one date
  Given ClassSchedule assigns instructor John
  And John is already teaching another class on Nov 15 at 10am
  When generation job runs
  Then all dates except Nov 15 are created
  And Nov 15 shows conflict warning
  And owner is notified to manually assign instructor for Nov 15
  And job logs conflict for review

Scenario: [Edge Case] Studio closed for holiday
  Given studio has closure date Dec 25 marked
  And ClassSchedule would generate class on Dec 25
  When job runs
  Then Dec 25 class is skipped
  And log shows "Skipped: Studio closure"
  And no notification (expected behavior)

Scenario: [Error Case] Room no longer exists
  Given ClassSchedule references room_id that was deleted
  When job attempts to generate classes
  Then job fails with clear error
  And owner is notified: "Cannot generate classes - Room deleted. Update schedule."
  And schedule is marked as needing attention
```

#### Phoenix/Elixir/Ash Implementation

**Domain**: Classes

**Oban Worker**:

```elixir
# lib/pilates_on_phx/classes/workers/generate_recurring_classes.ex
defmodule PilatesOnPhx.Classes.Workers.GenerateRecurringClasses do
  use Oban.Worker,
    queue: :recurring_classes,
    max_attempts: 2

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    # Find all active ClassSchedule records
    schedules =
      PilatesOnPhx.Classes.ClassSchedule
      |> Ash.Query.filter(active == true)
      |> Ash.Query.load([:studio, :class_type, :room, :instructor])
      |> PilatesOnPhx.Classes.read!()

    results =
      Enum.map(schedules, fn schedule ->
        generate_sessions_for_schedule(schedule)
      end)

    # Send summary email to studio owners
    send_generation_summary(results)

    {:ok, "Generated classes for #{length(schedules)} schedules"}
  end

  defp generate_sessions_for_schedule(schedule) do
    # Calculate dates for next 4 weeks
    start_date = Date.utc_today()
    end_date = Date.add(start_date, 28)  # 4 weeks

    # Get dates matching pattern
    matching_dates = calculate_matching_dates(
      schedule.recurrence_pattern,
      schedule.days_of_week,
      start_date,
      end_date
    )

    # Filter out existing sessions
    existing_dates = get_existing_session_dates(schedule)
    new_dates = Enum.reject(matching_dates, &(&1 in existing_dates))

    # Filter out studio closures
    closure_dates = get_studio_closure_dates(schedule.studio_id)
    valid_dates = Enum.reject(new_dates, &(&1 in closure_dates))

    # Create sessions
    {successes, failures} =
      Enum.reduce(valid_dates, {[], []}, fn date, {succ, fail} ->
        scheduled_at = DateTime.new!(date, schedule.time, "Etc/UTC")

        # Check conflicts
        case check_conflicts(schedule, scheduled_at) do
          :ok ->
            case create_session(schedule, scheduled_at) do
              {:ok, session} -> {[session | succ], fail}
              {:error, reason} -> {succ, [{date, reason} | fail]}
            end

          {:error, reason} ->
            {succ, [{date, reason} | fail]}
        end
      end)

    %{
      schedule_id: schedule.id,
      schedule_name: schedule.name,
      successes: successes,
      failures: failures,
      total_generated: length(successes)
    }
  end

  defp create_session(schedule, scheduled_at) do
    PilatesOnPhx.Classes.ClassSession
    |> Ash.Changeset.for_create(:auto_generate, %{
      class_schedule_id: schedule.id,
      class_type_id: schedule.class_type_id,
      studio_id: schedule.studio_id,
      room_id: schedule.room_id,
      instructor_id: schedule.instructor_id,
      scheduled_at: scheduled_at,
      duration_minutes: schedule.duration_minutes,
      max_capacity: schedule.max_capacity,
      status: :scheduled,
      auto_generated: true
    })
    |> Ash.create()
  end

  defp check_conflicts(schedule, scheduled_at) do
    # Check instructor conflict
    instructor_classes =
      PilatesOnPhx.Classes.ClassSession
      |> Ash.Query.filter(instructor_id == ^schedule.instructor_id)
      |> Ash.Query.filter(scheduled_at == ^scheduled_at)
      |> PilatesOnPhx.Classes.read!()

    if length(instructor_classes) > 0 do
      {:error, :instructor_conflict}
    else
      # Check room conflict
      room_classes =
        PilatesOnPhx.Classes.ClassSession
        |> Ash.Query.filter(room_id == ^schedule.room_id)
        |> Ash.Query.filter(scheduled_at == ^scheduled_at)
        |> PilatesOnPhx.Classes.read!()

      if length(room_classes) > 0 do
        {:error, :room_conflict}
      else
        :ok
      end
    end
  end

  defp calculate_matching_dates(:weekly, days_of_week, start_date, end_date) do
    start_date
    |> Date.range(end_date)
    |> Enum.filter(fn date ->
      day_num = Date.day_of_week(date)  # 1=Mon, 7=Sun
      day_num in days_of_week
    end)
  end

  defp send_generation_summary(results) do
    total_generated = Enum.sum(Enum.map(results, & &1.total_generated))
    total_failures = Enum.sum(Enum.map(results, &length(&1.failures)))

    # Send email to studio owners
    Enum.each(results, fn result ->
      schedule = get_schedule(result.schedule_id)

      PilatesOnPhx.Email.RecurringClassSummaryEmail.send(
        to: schedule.studio.owner_email,
        schedule_name: result.schedule_name,
        generated_count: result.total_generated,
        failures: result.failures
      )
    end)
  end
end
```

**Cron Configuration**:

```elixir
config :pilates_on_phx, Oban,
  plugins: [
    {Oban.Plugins.Cron,
      crontab: [
        # Every Sunday at 6am, generate classes for next 4 weeks
        {"0 6 * * 0", PilatesOnPhx.Classes.Workers.GenerateRecurringClasses}
      ]
    }
  ]
```

#### User Stories (Children)

- PHX-51: Weekly Class Generation Job
- PHX-52: Conflict Detection (Instructor/Room)
- PHX-53: Studio Closure Date Management
- PHX-54: Generation Summary Email
- PHX-55: Manual Override for Failed Generations

#### Dependencies

- PHX-4: Classes Domain
- PHX-11: Class Scheduling Epic (recurring templates)
- Oban configured

#### Testing Strategy

- Test date calculation logic
- Test conflict detection
- Test studio closure filtering
- Test Oban worker execution
- Test summary email
- Integration test for complete flow
- 85%+ coverage

---

## Sprint 4 - Integrations & Advanced Features

### Sprint 4 Project

**Name**: Sprint 4 - Integrations & Advanced Features
**Duration**: 3 weeks
**Priority**: High

#### Objectives

Integrate third-party services and implement advanced features that complete the platform's core functionality.

**Key Deliverables:**
1. **Stripe Payment Processing** - Secure package purchases
2. **Email Service Integration** - Professional transactional emails
3. **SMS Notifications** - Twilio integration
4. **Analytics & Reporting** - Business intelligence dashboards
5. **Mobile PWA Features** - Offline support, push notifications

#### Success Criteria

- Stripe payment success rate > 98%
- Email delivery rate > 99%
- SMS delivery rate > 95%
- Dashboard loads < 2 seconds
- PWA installable on iOS/Android
- 85%+ test coverage

---

### Epic PHX-56: Stripe Payment Processing

**Project**: Sprint 4 - Integrations & Advanced Features
**Priority**: Urgent (1)
**Labels**: epic, payments, stripe, revenue, sprint-4

#### Epic Overview

Integrate Stripe for secure payment processing for package purchases, memberships, and one-time fees. Support credit cards, Apple Pay, Google Pay.

**Original Source**: WLS-98 (Package Management), Industry standard

#### Problem Statement

Studios need secure, PCI-compliant payment processing. Manual payment tracking is error-prone and time-consuming. Stripe provides trusted infrastructure with modern payment methods.

#### Scope

**Payment Methods**:
- Credit/debit cards
- Apple Pay
- Google Pay
- ACH (future)

**Payment Flows**:
- Package purchase (one-time)
- Membership subscriptions (recurring)
- One-time fees (late cancellation, equipment)
- Refunds and adjustments

**Features**:
- Secure payment form (Stripe Elements)
- 3D Secure authentication
- Automatic receipt generation
- Refund processing
- Failed payment handling
- Payment history

#### Use Cases

```gherkin
Scenario: [Happy Path] Client purchases 10-class package
  Given client is logged in
  When they select "10-Class Package - $150"
  And they click "Purchase"
  Then Stripe payment form appears (Elements)
  And they enter card details
  And they click "Pay $150"
  Then Stripe processes payment
  And payment succeeds
  And ClientPackage is created with 10 credits
  And Payment record is created
  And client receives email receipt
  And they are redirected to dashboard showing new credits

Scenario: [Happy Path] Payment with Apple Pay
  Given client is on iPhone with Apple Pay setup
  When they select package and click "Purchase"
  Then Stripe shows Apple Pay button
  And they authenticate with Face ID
  And payment processes instantly
  And package is activated immediately

Scenario: [Edge Case] 3D Secure authentication required
  Given client's card requires 3DS
  When they submit payment
  Then Stripe redirects to bank authentication
  And client completes 3DS challenge
  And returns to app
  And payment completes successfully
  And package is activated

Scenario: [Error Case] Payment declined
  Given client submits payment
  When Stripe returns declined (insufficient funds)
  Then user-friendly error shows: "Payment declined. Please try different card."
  And no package is created
  And failed attempt is logged
  And client can retry with different card
```

#### Phoenix/Elixir/Ash Implementation

**Domain**: Bookings (payments are part of booking workflow)

**Stripe Service**:

```elixir
# lib/pilates_on_phx/bookings/stripe_service.ex
defmodule PilatesOnPhx.Bookings.StripeService do
  @moduledoc """
  Stripe payment processing service.
  """

  def create_payment_intent(amount_cents, client_id, package_id) do
    Stripe.PaymentIntent.create(%{
      amount: amount_cents,
      currency: "usd",
      automatic_payment_methods: %{enabled: true},
      metadata: %{
        client_id: client_id,
        package_id: package_id
      }
    })
  end

  def confirm_payment(payment_intent_id) do
    Stripe.PaymentIntent.retrieve(payment_intent_id)
  end

  def create_refund(payment_intent_id, amount_cents, reason) do
    Stripe.Refund.create(%{
      payment_intent: payment_intent_id,
      amount: amount_cents,
      reason: reason  # "requested_by_customer", "fraudulent", etc.
    })
  end
end
```

**Payment Resource**:

```elixir
# lib/pilates_on_phx/bookings/payment.ex (expanded)
defmodule PilatesOnPhx.Bookings.Payment do
  use Ash.Resource,
    domain: PilatesOnPhx.Bookings,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key :id
    attribute :amount_cents, :integer
    attribute :stripe_payment_intent_id, :string
    attribute :stripe_charge_id, :string
    attribute :status, :atom # :pending, :succeeded, :failed, :refunded
    attribute :payment_method, :atom # :card, :apple_pay, :google_pay
    attribute :payment_type, :atom # :package_purchase, :membership, :fee, :refund
    attribute :receipt_url, :string
    attribute :failure_code, :string
    attribute :failure_message, :string
    timestamps()
  end

  relationships do
    belongs_to :client, PilatesOnPhx.Bookings.Client
    belongs_to :client_package, PilatesOnPhx.Bookings.ClientPackage
  end

  actions do
    create :initiate_purchase do
      argument :package_id, :uuid
      argument :client_id, :uuid
      argument :amount_cents, :integer

      change create_stripe_payment_intent()
      change set_attribute(:status, :pending)
    end

    update :confirm_payment do
      argument :payment_intent_id, :string

      validate payment_intent_succeeded()
      change set_attribute(:status, :succeeded)
      change activate_package()
      change send_receipt()
    end

    update :mark_failed do
      argument :failure_code, :string
      argument :failure_message, :string

      change set_attribute(:status, :failed)
      change log_failure()
    end

    update :process_refund do
      argument :refund_amount_cents, :integer
      argument :reason, :string

      change create_stripe_refund()
      change set_attribute(:status, :refunded)
      change notify_client()
    end
  end
end
```

**LiveView Payment Flow**:

```elixir
# lib/pilates_on_phx_web/live/package/purchase_live.ex
defmodule PilatesOnPhxWeb.Package.PurchaseLive do
  use PilatesOnPhxWeb, :live_view

  def mount(%{"package_id" => package_id}, _session, socket) do
    package = get_package(package_id)
    client = socket.assigns.current_user.client

    # Create payment intent
    {:ok, payment_intent} =
      PilatesOnPhx.Bookings.StripeService.create_payment_intent(
        package.price_cents,
        client.id,
        package.id
      )

    {:ok, assign(socket,
      package: package,
      client_secret: payment_intent.client_secret,
      payment_intent_id: payment_intent.id
    )}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-lg mx-auto p-6">
      <h1>Purchase <%= @package.name %></h1>
      <p><%= @package.total_credits %> credits for $<%= Money.to_string(@package.price_cents) %></p>

      <!-- Stripe Elements payment form -->
      <div id="payment-element" phx-hook="StripePayment" data-client-secret={@client_secret}></div>

      <button id="submit-payment" class="btn-primary">
        Pay $<%= Money.to_string(@package.price_cents) %>
      </button>

      <div id="payment-message" class="hidden"></div>
    </div>
    """
  end

  def handle_event("payment_succeeded", %{"payment_intent_id" => intent_id}, socket) do
    # Confirm payment and activate package
    case confirm_and_activate_package(intent_id, socket.assigns.client) do
      {:ok, client_package} ->
        {:noreply, redirect(socket, to: "/dashboard?purchase=success")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Payment failed: #{reason}")}
    end
  end

  def handle_event("payment_failed", %{"error" => error}, socket) do
    # Log failed payment
    log_failed_payment(socket.assigns.payment_intent_id, error)

    {:noreply, put_flash(socket, :error, "Payment declined: #{error["message"]}")}
  end
end
```

**Stripe Elements Hook** (JavaScript):

```javascript
// assets/js/hooks/stripe_payment.js
export const StripePayment = {
  mounted() {
    const stripe = Stripe(stripePublishableKey);
    const clientSecret = this.el.dataset.clientSecret;

    const elements = stripe.elements({ clientSecret });
    const paymentElement = elements.create('payment');
    paymentElement.mount('#payment-element');

    document.getElementById('submit-payment').addEventListener('click', async () => {
      const {error, paymentIntent} = await stripe.confirmPayment({
        elements,
        confirmParams: {
          return_url: window.location.href,
        },
        redirect: 'if_required'
      });

      if (error) {
        this.pushEvent("payment_failed", {error: error});
      } else if (paymentIntent.status === 'succeeded') {
        this.pushEvent("payment_succeeded", {payment_intent_id: paymentIntent.id});
      }
    });
  }
};
```

**Stripe Webhook Handler**:

```elixir
# lib/pilates_on_phx_web/controllers/stripe_webhook_controller.ex
defmodule PilatesOnPhxWeb.StripeWebhookController do
  use PilatesOnPhxWeb, :controller

  def create(conn, params) do
    # Verify webhook signature
    signature = get_req_header(conn, "stripe-signature") |> List.first()

    case Stripe.Webhook.construct_event(
      conn.assigns.raw_body,
      signature,
      Application.get_env(:pilates_on_phx, :stripe_webhook_secret)
    ) do
      {:ok, %Stripe.Event{type: "payment_intent.succeeded", data: %{object: payment_intent}}} ->
        handle_payment_succeeded(payment_intent)
        send_resp(conn, 200, "ok")

      {:ok, %Stripe.Event{type: "payment_intent.payment_failed", data: %{object: payment_intent}}} ->
        handle_payment_failed(payment_intent)
        send_resp(conn, 200, "ok")

      {:ok, %Stripe.Event{type: "charge.refunded", data: %{object: charge}}} ->
        handle_refund(charge)
        send_resp(conn, 200, "ok")

      {:error, _reason} ->
        send_resp(conn, 400, "invalid signature")
    end
  end

  defp handle_payment_succeeded(payment_intent) do
    # Find payment record and activate package
    payment = get_payment_by_intent_id(payment_intent.id)

    payment
    |> Ash.Changeset.for_update(:confirm_payment, %{
      payment_intent_id: payment_intent.id
    })
    |> Ash.update!()
  end
end
```

#### User Stories (Children)

- PHX-57: Stripe Account Setup & Configuration
- PHX-58: Payment Intent Creation
- PHX-59: Stripe Elements Payment Form (LiveView)
- PHX-60: Payment Confirmation & Package Activation
- PHX-61: Webhook Handler for Payment Events
- PHX-62: Refund Processing
- PHX-63: Payment History & Receipts

#### Dependencies

- PHX-9: Bookings Domain
- Sprint 2 complete (package purchases)
- Stripe account (test mode for development)

#### Testing Strategy

- Test payment intent creation
- Test successful payment flow (mock Stripe)
- Test failed payment handling
- Test refund processing
- Test webhook signature verification
- Test 3D Secure flow
- Integration test with Stripe test cards
- 85%+ coverage

---

## Backlog - Future Sprints

### Epic PHX-64: Advanced Analytics & Business Intelligence

**Priority**: Medium
**Labels**: backlog, analytics, reporting

#### Overview

Advanced analytics dashboards with trends, forecasting, and business insights.

**Features**:
- Revenue forecasting
- Client retention analytics
- Class popularity trends
- Instructor performance metrics
- Peak hour analysis
- Churn prediction

**User Stories**:
- PHX-65: Revenue Dashboard with Trends
- PHX-66: Client Retention Analysis
- PHX-67: Class Popularity Heatmap
- PHX-68: Instructor Performance Metrics
- PHX-69: Predictive Analytics (ML-based)

---

### Epic PHX-70: Mobile PWA Features

**Priority**: Medium
**Labels**: backlog, mobile, pwa

#### Overview

Progressive Web App features for mobile experience.

**Features**:
- Install prompt
- Offline booking queue
- Push notifications
- Background sync
- App-like navigation

**User Stories**:
- PHX-71: PWA Manifest & Service Worker
- PHX-72: Offline Booking Queue
- PHX-73: Push Notification Setup
- PHX-74: Background Sync for Data
- PHX-75: App Install Prompt

---

### Epic PHX-76: Advanced Package Features

**Priority**: Low
**Labels**: backlog, packages

#### Overview

Advanced package management features.

**Features**:
- Package pause/freeze
- Package sharing (family plans)
- Auto-renewal subscriptions
- Package transfer between clients
- Bulk package purchases (corporate)

**User Stories**:
- PHX-77: Package Pause/Freeze
- PHX-78: Package Sharing (Family Plans)
- PHX-79: Auto-Renewal Subscriptions
- PHX-80: Package Transfer
- PHX-81: Corporate/Bulk Purchases

---

### Epic PHX-82: Instructor Features

**Priority**: Medium
**Labels**: backlog, instructors

#### Overview

Instructor-specific features and portals.

**Features**:
- Instructor availability calendar
- Class notes and prep
- Client progress tracking
- Private messaging with clients
- Instructor earnings dashboard

**User Stories**:
- PHX-83: Instructor Availability Management
- PHX-84: Class Notes & Preparation
- PHX-85: Client Progress Tracking
- PHX-86: Instructor-Client Messaging
- PHX-87: Earnings Dashboard

---

## Summary

### Sprint 3 (3 weeks)
- **Epics**: 3 (Reminders, Reports, Recurring Automation)
- **User Stories**: ~15
- **Focus**: Automation, Oban jobs, Email/SMS

### Sprint 4 (3 weeks)
- **Epics**: 3 (Payments, Communications, Analytics)
- **User Stories**: ~15
- **Focus**: Stripe, Email/SMS services, Dashboards

### Backlog (Future)
- **Epics**: 5+ (Advanced Analytics, Mobile PWA, Advanced Packages, Instructor Features, etc.)
- **User Stories**: 30+
- **Focus**: Enhancement and differentiation features

### Total Roadmap
- **4 Sprints**: ~11 weeks
- **Total Epics**: 12+
- **Total User Stories**: 80+
- **Complete Platform**: Full-featured Pilates studio management system

---

## Next Steps

1. **Create Epic PHX-34, PHX-42, PHX-50** in Linear (copy from this document)
2. **Create all Sprint 3 user stories** (15 stories)
3. **Create Sprint 4 project** in Linear
4. **Create Sprint 4 epics and stories** (15 stories)
5. **Add backlog epics** to Linear for future planning

All specifications follow the same comprehensive template with Phoenix/Elixir/Ash implementation details, testing strategies, and dependencies.
