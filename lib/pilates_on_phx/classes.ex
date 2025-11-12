defmodule PilatesOnPhx.Classes do
  @moduledoc """
  The Classes domain manages class scheduling, session management, and attendance tracking.

  This domain handles everything related to Pilates classes including class types,
  recurring schedules, specific class sessions, instructor assignments, and attendance
  check-ins. It provides the core scheduling functionality that drives the booking system.

  ## Resources

  - **ClassType**: Categories of classes (Reformer, Mat, Barre, Tower, etc.)
  - **ClassSchedule**: Recurring schedule templates for regular classes
  - **ClassSession**: Specific instances of scheduled classes with date/time
  - **Attendance**: Check-in records and attendance tracking for class sessions

  ## Responsibilities

  - Class type definition and categorization
  - Recurring schedule management
  - Class session instantiation from schedules
  - Instructor assignment to sessions
  - Capacity management and availability tracking
  - Attendance check-in and no-show tracking
  - Class cancellation and rescheduling
  - Session-specific notes and modifications

  ## Multi-Tenant Strategy

  Classes are scoped to studios, which belong to organizations. All class operations
  require proper authorization through the actor pattern:

      policies do
        policy action_type(:read) do
          authorize_if expr(organization_id == ^actor(:organization_id))
        end

        policy action_type([:create, :update, :destroy]) do
          authorize_if relates_to_actor_via(:studio, :organization_id)
        end
      end

  ## Authorization Patterns

  - **Owners**: Full access to all classes in their organization
  - **Instructors**: Read access to all classes, write access to their assigned classes
  - **Clients**: Read access to available classes for booking

  ## High Cohesion Design

  This domain combines scheduling and attendance because they are tightly coupled:
  - Schedules create sessions
  - Sessions require attendance tracking
  - Attendance affects future scheduling decisions
  - All operate within the class lifecycle

  ## Cross-Domain Interactions

  - **Studios Domain**: Classes are scheduled in studios and rooms
  - **Accounts Domain**: Instructors (users) are assigned to classes
  - **Bookings Domain**: Clients book class sessions, affecting capacity

  ## Usage Examples

      # Create a class type
      class_type =
        ClassType
        |> Ash.Changeset.for_create(:create, %{
          name: "Reformer Level 1",
          description: "Beginner reformer class",
          duration_minutes: 55,
          studio_id: studio.id
        }, actor: owner)
        |> Ash.create!()

      # Create a recurring schedule
      schedule =
        ClassSchedule
        |> Ash.Changeset.for_create(:create, %{
          class_type_id: class_type.id,
          studio_id: studio.id,
          room_id: room.id,
          instructor_id: instructor.id,
          day_of_week: "monday",
          start_time: ~T[09:00:00],
          capacity: 8
        }, actor: owner)
        |> Ash.create!()

      # Generate sessions from schedule
      sessions =
        ClassSchedule
        |> Ash.get!(schedule.id, actor: owner)
        |> ClassSchedule.generate_sessions(start_date, end_date)

      # Check-in a client for attendance
      attendance =
        Attendance
        |> Ash.Changeset.for_create(:check_in, %{
          session_id: session.id,
          client_id: client.id,
          checked_in_at: DateTime.utc_now()
        }, actor: instructor)
        |> Ash.create!()

      # Query available sessions
      available_sessions =
        ClassSession
        |> Ash.Query.filter(
          studio_id == ^studio.id and
          start_time >= ^DateTime.utc_now() and
          available_spots > 0
        )
        |> Ash.read!(actor: client)
  """

  use Ash.Domain

  resources do
    # Resources will be added in subsequent issues (PHX-4)
    # - PilatesOnPhx.Classes.ClassType
    # - PilatesOnPhx.Classes.ClassSchedule
    # - PilatesOnPhx.Classes.ClassSession
    # - PilatesOnPhx.Classes.Attendance
  end
end
