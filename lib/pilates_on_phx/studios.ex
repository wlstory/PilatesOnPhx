defmodule PilatesOnPhx.Studios do
  @moduledoc """
  The Studios domain manages studio facilities, physical locations, and studio configuration.

  This domain handles all studio-related entities including studio profiles, settings,
  staff assignments, rooms, and equipment inventory. Studios are the primary organizational
  unit for scheduling classes and managing operations.

  ## Resources

  - **Studio**: Studio profile, settings, and configuration
  - **StudioStaff**: Staff assignments and permissions for studio operations
  - **Room**: Physical spaces within studios where classes are held
  - **Equipment**: Equipment inventory and availability tracking

  ## Responsibilities

  - Studio profile and branding management
  - Business hours and operating schedule configuration
  - Physical location and facility management
  - Staff role assignments and permissions
  - Room capacity and availability tracking
  - Equipment inventory management
  - Studio-level settings and preferences

  ## Multi-Tenant Strategy

  Studios belong to organizations (from Accounts domain). All studio operations
  are scoped to the user's organization through the actor pattern:

      policies do
        policy action_type(:read) do
          authorize_if actor_attribute_equals(:organization_id, :organization_id)
        end
      end

  ## Authorization Patterns

  - **Owners**: Full access to all studio data and configuration
  - **Instructors**: Read access to studios where they're assigned
  - **Clients**: Read access to studio public information only

  ## Cross-Domain Interactions

  - **Accounts Domain**: Studios belong to organizations, created by owners
  - **Classes Domain**: Classes are scheduled in studios and rooms
  - **Bookings Domain**: Clients book classes at specific studios

  ## Usage Examples

      # Create a new studio (owner action)
      studio =
        Studio
        |> Ash.Changeset.for_create(:create, %{
          name: "Downtown Pilates Studio",
          address: "123 Main St",
          organization_id: org.id
        }, actor: owner)
        |> Ash.create!()

      # Assign staff to studio
      staff_assignment =
        StudioStaff
        |> Ash.Changeset.for_create(:assign, %{
          studio_id: studio.id,
          user_id: instructor.id,
          role: :instructor
        }, actor: owner)
        |> Ash.create!()

      # Query studios in organization
      studios =
        Studio
        |> Ash.Query.filter(organization_id == ^org_id)
        |> Ash.read!(actor: current_user)

      # Get rooms for a studio
      rooms =
        Room
        |> Ash.Query.filter(studio_id == ^studio.id)
        |> Ash.read!(actor: current_user)
  """

  use Ash.Domain

  resources do
    # Resources will be added in subsequent issues (PHX-3)
    # - PilatesOnPhx.Studios.Studio
    # - PilatesOnPhx.Studios.StudioStaff
    # - PilatesOnPhx.Studios.Room
    # - PilatesOnPhx.Studios.Equipment
  end
end
