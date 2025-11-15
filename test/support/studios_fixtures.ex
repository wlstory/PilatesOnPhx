defmodule PilatesOnPhx.StudiosFixtures do
  @moduledoc """
  Test fixtures for Studios domain resources.

  These fixtures create test data through proper Ash domain actions, ensuring:
  - All business logic is exercised
  - Authorization policies are respected (with test bypass for fixture creation)
  - Multi-tenant boundaries are enforced
  - Cross-domain relationships work correctly
  - Resources are created in valid states

  CRITICAL: Always use domain actions, never bypass domain layer.
  """

  alias PilatesOnPhx.AccountsFixtures
  alias PilatesOnPhx.Studios
  alias PilatesOnPhx.Studios.{Equipment, Room, Studio, StudioStaff}

  require Ash.Query

  @doc """
  Returns a bypass actor for test fixtures that bypasses authorization policies.
  This allows test setup to create resources without complex authorization chains.
  """
  def bypass_actor do
    %{bypass_strict_access: true}
  end

  @doc """
  Creates a studio with valid attributes.

  ## Options
    * `:name` - Studio name (default: generated unique name)
    * `:address` - Studio address (default: generated address)
    * `:timezone` - Timezone (default: "America/New_York")
    * `:max_capacity` - Maximum capacity (default: 50)
    * `:operating_hours` - Operating hours map (default: standard hours)
    * `:settings` - JSON settings (default: %{})
    * `:active` - Active status (default: true)
    * `:organization` - Organization to belong to (creates one if not provided)

  ## Examples

      iex> create_studio()
      %Studio{name: "Test Studio 1", active: true}

      iex> create_studio(name: "Downtown Pilates", max_capacity: 100)
      %Studio{name: "Downtown Pilates", max_capacity: 100}
  """
  def create_studio(attrs \\ %{}) do
    # Convert keyword list to map
    attrs_map = Enum.into(attrs, %{})
    unique_id = System.unique_integer([:positive])

    # Create organization if not provided
    organization =
      case Map.get(attrs_map, :organization) do
        nil -> AccountsFixtures.create_organization()
        org -> org
      end

    default_operating_hours = %{
      "mon" => "6:00-20:00",
      "tue" => "6:00-20:00",
      "wed" => "6:00-20:00",
      "thu" => "6:00-20:00",
      "fri" => "6:00-20:00",
      "sat" => "8:00-18:00",
      "sun" => "8:00-16:00"
    }

    studio_attrs =
      %{
        name: "Test Studio #{unique_id}",
        address: "#{unique_id} Main St, Test City, TC 12345",
        timezone: "America/New_York",
        max_capacity: 50,
        operating_hours: default_operating_hours,
        settings: %{},
        active: true,
        organization_id: organization.id
      }
      |> Map.merge(attrs_map)
      |> Map.delete(:organization)

    Studio
    |> Ash.Changeset.for_create(:create, studio_attrs)
    |> Ash.create!(domain: Studios, actor: bypass_actor())
  end

  @doc """
  Creates a studio staff assignment with valid attributes.

  ## Options
    * `:studio` - Studio to assign to (creates one if not provided)
    * `:user` - User to assign (creates one if not provided)
    * `:role` - Staff role (:instructor, :front_desk, :manager) (default: :instructor)
    * `:permissions` - List of permission strings (default: ["teach", "view_schedule"])
    * `:notes` - Optional notes (default: nil)
    * `:active` - Active status (default: true)

  ## Examples

      iex> create_studio_staff()
      %StudioStaff{role: :instructor, active: true}

      iex> create_studio_staff(role: :manager, permissions: ["teach", "manage"])
      %StudioStaff{role: :manager, permissions: ["teach", "manage"]}
  """
  def create_studio_staff(attrs \\ %{}) do
    # Convert keyword list to map
    attrs_map = Enum.into(attrs, %{})

    # Create studio if not provided
    studio =
      case Map.get(attrs_map, :studio) do
        nil -> create_studio()
        studio -> studio
      end

    # Create user if not provided
    user =
      case Map.get(attrs_map, :user) do
        nil ->
          # Load organization with bypass actor to avoid authorization issues
          loaded_studio = Ash.load!(studio, :organization, actor: bypass_actor())

          AccountsFixtures.create_user(
            role: :instructor,
            organization: loaded_studio.organization
          )

        user ->
          user
      end

    staff_attrs =
      %{
        studio_id: studio.id,
        user_id: user.id,
        role: :instructor,
        permissions: ["teach", "view_schedule"],
        notes: nil,
        active: true
      }
      |> Map.merge(attrs_map)
      |> Map.delete(:studio)
      |> Map.delete(:user)

    StudioStaff
    |> Ash.Changeset.for_create(:assign, staff_attrs)
    |> Ash.create!(domain: Studios, actor: bypass_actor())
  end

  @doc """
  Creates a room with valid attributes.

  ## Options
    * `:name` - Room name (default: generated unique name)
    * `:capacity` - Room capacity (default: 12)
    * `:settings` - JSON settings (default: %{})
    * `:active` - Active status (default: true)
    * `:studio` - Studio to belong to (creates one if not provided)

  ## Examples

      iex> create_room()
      %Room{name: "Test Room 1", capacity: 12}

      iex> create_room(name: "Studio A", capacity: 20)
      %Room{name: "Studio A", capacity: 20}
  """
  def create_room(attrs \\ %{}) do
    # Convert keyword list to map
    attrs_map = Enum.into(attrs, %{})
    unique_id = System.unique_integer([:positive])

    # Create studio if not provided
    studio =
      case Map.get(attrs_map, :studio) do
        nil -> create_studio()
        studio -> studio
      end

    room_attrs =
      %{
        name: "Test Room #{unique_id}",
        capacity: 12,
        settings: %{},
        active: true,
        studio_id: studio.id
      }
      |> Map.merge(attrs_map)
      |> Map.delete(:studio)

    Room
    |> Ash.Changeset.for_create(:create, room_attrs)
    |> Ash.create!(domain: Studios, actor: bypass_actor())
  end

  @doc """
  Creates equipment with valid attributes.

  ## Options
    * `:name` - Equipment name (default: generated unique name)
    * `:equipment_type` - Type of equipment (default: "reformer")
    * `:serial_number` - Serial number (default: nil)
    * `:portable` - Can equipment be moved? (default: false)
    * `:maintenance_notes` - Maintenance notes (default: nil)
    * `:active` - Active status (default: true)
    * `:studio` - Studio to belong to (creates one if not provided)
    * `:room` - Room to assign to (default: nil, creates studio's room if portable: false)

  ## Examples

      iex> create_equipment()
      %Equipment{name: "Test Equipment 1", equipment_type: "reformer"}

      iex> create_equipment(name: "Reformer 1", portable: true)
      %Equipment{name: "Reformer 1", portable: true, room_id: nil}
  """
  def create_equipment(attrs \\ %{}) do
    # Convert keyword list to map
    attrs_map = Enum.into(attrs, %{})
    unique_id = System.unique_integer([:positive])

    # Create studio if not provided
    studio =
      case Map.get(attrs_map, :studio) do
        nil -> create_studio()
        studio -> studio
      end

    # Determine room assignment based on portable flag
    room_id =
      cond do
        # Explicitly provided room
        Map.has_key?(attrs_map, :room) && attrs_map.room != nil ->
          attrs_map.room.id

        # Explicitly set to nil (portable equipment)
        Map.has_key?(attrs_map, :room) && attrs_map.room == nil ->
          nil

        # Not portable and no room specified - create one
        !Map.get(attrs_map, :portable, false) ->
          create_room(studio: studio).id

        # Portable and no room specified
        true ->
          nil
      end

    equipment_attrs =
      %{
        name: "Test Equipment #{unique_id}",
        equipment_type: "reformer",
        serial_number: nil,
        portable: false,
        maintenance_notes: nil,
        active: true,
        studio_id: studio.id,
        room_id: room_id
      }
      |> Map.merge(attrs_map)
      |> Map.delete(:studio)
      |> Map.delete(:room)

    Equipment
    |> Ash.Changeset.for_create(:create, equipment_attrs)
    |> Ash.create!(domain: Studios, actor: bypass_actor())
  end

  @doc """
  Creates a complete studio setup with rooms, staff, and equipment.

  ## Options
    * `:studio_attrs` - Attributes for the studio
    * `:num_rooms` - Number of rooms to create (default: 2)
    * `:num_staff` - Number of staff to create (default: 1)
    * `:num_equipment` - Number of equipment items per room (default: 2)

  ## Examples

      iex> create_complete_studio_setup()
      %{
        studio: %Studio{},
        rooms: [%Room{}, %Room{}],
        staff: [%StudioStaff{}],
        equipment: [%Equipment{}, %Equipment{}, %Equipment{}, %Equipment{}]
      }
  """
  def create_complete_studio_setup(attrs \\ %{}) do
    studio_attrs = Map.get(attrs, :studio_attrs, %{})
    num_rooms = Map.get(attrs, :num_rooms, 2)
    num_staff = Map.get(attrs, :num_staff, 1)
    num_equipment = Map.get(attrs, :num_equipment, 2)

    # Create studio
    studio = create_studio(studio_attrs)

    # Create organization for context
    organization = Ash.load!(studio, :organization).organization

    # Create rooms
    rooms =
      for i <- 1..num_rooms do
        create_room(
          studio: studio,
          name: "Room #{i}",
          capacity: 10 + i * 2
        )
      end

    # Create staff
    staff =
      for i <- 1..num_staff do
        create_studio_staff(
          studio: studio,
          user: AccountsFixtures.create_user(organization: organization, role: :instructor),
          role: if(i == 1, do: :instructor, else: :front_desk)
        )
      end

    # Create equipment (distributed across rooms)
    equipment =
      for room <- rooms, i <- 1..num_equipment do
        create_equipment(
          studio: studio,
          room: room,
          name: "#{room.name} Equipment #{i}",
          equipment_type: if(i == 1, do: "reformer", else: "mat")
        )
      end

    %{
      studio: studio,
      rooms: rooms,
      staff: staff,
      equipment: equipment
    }
  end
end
