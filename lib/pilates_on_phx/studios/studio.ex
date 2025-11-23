defmodule PilatesOnPhx.Studios.Studio do
  @moduledoc """
  Represents a physical studio location in the PilatesOnPhx platform.

  Studios are physical locations where classes are held. Each studio belongs to an organization
  and can have multiple rooms, staff assignments, and equipment.

  ## Attributes

  - `:name` - Studio name (e.g., "Downtown Pilates")
  - `:address` - Physical address of the studio
  - `:timezone` - IANA timezone for scheduling (default: "America/New_York")
  - `:max_capacity` - Maximum total capacity across all rooms (default: 50)
  - `:operating_hours` - DEPRECATED: Map of day-of-week to hours (e.g., %{"mon" => "6:00-20:00"})
  - `:regular_hours` - Map of weekday to open/close times or "closed" (e.g., %{"monday" => %{"open" => "06:00", "close" => "20:00"}})
  - `:special_hours` - List of special hours for holidays/events (e.g., [%{"date" => "2025-12-25", "closed" => true, "reason" => "Christmas"}])
  - `:settings` - JSON map for studio-specific settings (wifi, parking, amenities)
  - `:active` - Whether the studio is currently active

  ## Relationships

  - `belongs_to :organization` - The organization that owns this studio
  - `has_many :staff_assignments` - Staff assigned to this studio
  - `has_many :rooms` - Rooms within this studio
  - `has_many :equipment` - Equipment at this studio

  ## Authorization

  - Organization members can read studios
  - Organization owners can create/update/deactivate studios
  - Multi-tenant isolation enforced via organization_id
  """

  use Ash.Resource,
    domain: PilatesOnPhx.Studios,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "studios"
    repo PilatesOnPhx.Repo

    references do
      reference :organization, on_delete: :delete
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true

      constraints min_length: 1,
                  max_length: 255,
                  trim?: true
    end

    attribute :address, :string do
      allow_nil? false
      public? true

      constraints min_length: 1,
                  max_length: 500,
                  trim?: true
    end

    attribute :timezone, :string do
      allow_nil? false
      default "America/New_York"
      public? true
    end

    attribute :max_capacity, :integer do
      allow_nil? false
      default 50
      public? true

      constraints min: 1, max: 500
    end

    attribute :operating_hours, :map do
      allow_nil? false

      default %{
        "mon" => "6:00-20:00",
        "tue" => "6:00-20:00",
        "wed" => "6:00-20:00",
        "thu" => "6:00-20:00",
        "fri" => "6:00-20:00",
        "sat" => "8:00-18:00",
        "sun" => "8:00-16:00"
      }

      public? true
    end

    attribute :regular_hours, :map do
      allow_nil? true
      default %{}
      public? true
    end

    attribute :special_hours, {:array, :map} do
      allow_nil? true
      default []
      public? true
    end

    attribute :settings, :map do
      allow_nil? false
      default %{}
      public? true
    end

    attribute :active, :boolean do
      allow_nil? false
      default true
      public? true
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :organization, PilatesOnPhx.Accounts.Organization do
      allow_nil? false
      attribute_writable? true
    end

    has_many :staff_assignments, PilatesOnPhx.Studios.StudioStaff do
      destination_attribute :studio_id
    end

    has_many :rooms, PilatesOnPhx.Studios.Room do
      destination_attribute :studio_id
    end

    has_many :equipment, PilatesOnPhx.Studios.Equipment do
      destination_attribute :studio_id
    end
  end

  validations do
    validate fn changeset, _context ->
      case Ash.Changeset.get_attribute(changeset, :timezone) do
        nil ->
          :ok

        timezone ->
          # Validate against a list of common IANA timezones
          valid_timezones = [
            "UTC",
            "GMT",
            # Americas
            "America/New_York",
            "America/Chicago",
            "America/Denver",
            "America/Los_Angeles",
            "America/Phoenix",
            "America/Anchorage",
            "America/Honolulu",
            "America/Toronto",
            "America/Vancouver",
            "America/Mexico_City",
            "America/Sao_Paulo",
            "America/Buenos_Aires",
            # Europe
            "Europe/London",
            "Europe/Paris",
            "Europe/Berlin",
            "Europe/Rome",
            "Europe/Madrid",
            "Europe/Amsterdam",
            "Europe/Brussels",
            "Europe/Vienna",
            "Europe/Stockholm",
            "Europe/Copenhagen",
            "Europe/Dublin",
            "Europe/Lisbon",
            "Europe/Athens",
            "Europe/Prague",
            "Europe/Warsaw",
            "Europe/Moscow",
            # Asia
            "Asia/Tokyo",
            "Asia/Seoul",
            "Asia/Shanghai",
            "Asia/Hong_Kong",
            "Asia/Singapore",
            "Asia/Bangkok",
            "Asia/Dubai",
            "Asia/Kolkata",
            "Asia/Jerusalem",
            "Asia/Tehran",
            # Pacific
            "Pacific/Auckland",
            "Pacific/Sydney",
            "Pacific/Melbourne",
            "Pacific/Fiji",
            "Pacific/Guam",
            # Australia
            "Australia/Sydney",
            "Australia/Melbourne",
            "Australia/Brisbane",
            "Australia/Perth",
            "Australia/Adelaide"
          ]

          if timezone in valid_timezones do
            :ok
          else
            {:error,
             field: :timezone,
             message: "must be a valid IANA timezone (e.g., 'America/New_York', 'Europe/London')"}
          end
      end
    end

    # Validate regular_hours structure and format
    validate fn changeset, _context ->
      case Ash.Changeset.get_attribute(changeset, :regular_hours) do
        nil -> :ok
        hours when hours == %{} -> :ok
        hours when is_map(hours) ->
          valid_days = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]

          # Validate each day's hours
          Enum.reduce_while(hours, :ok, fn {day, value}, _acc ->
            cond do
              day not in valid_days ->
                {:halt, {:error, field: :regular_hours, message: "contains invalid day name: #{day}. Must be one of: #{Enum.join(valid_days, ", ")}"}}

              value == "closed" ->
                {:cont, :ok}

              is_map(value) ->
                case validate_hours_map(value, day) do
                  :ok -> {:cont, :ok}
                  error -> {:halt, error}
                end

              true ->
                {:halt, {:error, field: :regular_hours, message: "#{day} must be either 'closed' or a map with 'open' and 'close' keys"}}
            end
          end)

        _ ->
          {:error, field: :regular_hours, message: "must be a map"}
      end
    end

    # Validate special_hours structure and format (including duplicate check and sorting)
    validate fn changeset, _context ->
      case Ash.Changeset.get_attribute(changeset, :special_hours) do
        nil -> changeset
        [] -> changeset
        hours when is_list(hours) ->
          # First validate each entry
          validation_result = Enum.reduce_while(hours, :ok, fn entry, _acc ->
            cond do
              not is_map(entry) ->
                {:halt, {:error, field: :special_hours, message: "each entry must be a map"}}

              not Map.has_key?(entry, "date") ->
                {:halt, {:error, field: :special_hours, message: "each entry must have a 'date' field"}}

              not Map.has_key?(entry, "reason") ->
                {:halt, {:error, field: :special_hours, message: "each entry must have a 'reason' field"}}

              true ->
                case validate_special_hours_entry(entry) do
                  :ok -> {:cont, :ok}
                  error -> {:halt, error}
                end
            end
          end)

          # If validation passed, check for duplicate dates and sort
          case validation_result do
            :ok ->
              # Check for duplicate dates
              dates = Enum.map(hours, & &1["date"])
              unique_dates = Enum.uniq(dates)

              if length(dates) != length(unique_dates) do
                Ash.Changeset.add_error(changeset, field: :special_hours, message: "duplicate dates found in special hours")
              else
                # Sort special_hours by date
                sorted_hours = Enum.sort_by(hours, & &1["date"])

                # Update the changeset with sorted hours
                Ash.Changeset.force_change_attribute(changeset, :special_hours, sorted_hours)
              end

            error ->
              Ash.Changeset.add_error(changeset, error)
          end

        _ ->
          Ash.Changeset.add_error(changeset, field: :special_hours, message: "must be a list")
      end
    end
  end

  # Helper function to validate hours map (open/close times)
  defp validate_hours_map(hours_map, day) do
    cond do
      not Map.has_key?(hours_map, "open") ->
        {:error, field: :regular_hours, message: "#{day} is missing 'open' time"}

      not Map.has_key?(hours_map, "close") ->
        {:error, field: :regular_hours, message: "#{day} is missing 'close' time"}

      true ->
        with :ok <- validate_time_format(hours_map["open"], "#{day}.open"),
             :ok <- validate_time_format(hours_map["close"], "#{day}.close") do
          :ok
        end
    end
  end

  # Helper function to validate time format (HH:MM)
  defp validate_time_format(time, field) do
    case Regex.match?(~r/^([01]\d|2[0-3]):([0-5]\d)$/, time) do
      true -> :ok
      false -> {:error, field: :regular_hours, message: "#{field} must be in HH:MM format (00:00 to 23:59), got: #{time}"}
    end
  end

  # Helper function to validate special hours entry
  defp validate_special_hours_entry(entry) do
    with :ok <- validate_date_format(entry["date"]),
         :ok <- validate_special_hours_consistency(entry) do
      # If entry has open/close times, validate their format
      # Only validate if values are not nil (closed entries won't have these)
      if Map.has_key?(entry, "open") and Map.has_key?(entry, "close") and
         entry["open"] != nil and entry["close"] != nil do
        with :ok <- validate_special_time_format(entry["open"], "open"),
             :ok <- validate_special_time_format(entry["close"], "close") do
          :ok
        end
      else
        :ok
      end
    end
  end

  # Helper function to validate date format (ISO 8601: YYYY-MM-DD)
  defp validate_date_format(date) do
    case Regex.match?(~r/^\d{4}-\d{2}-\d{2}$/, date) do
      true -> :ok
      false -> {:error, field: :special_hours, message: "date must be in YYYY-MM-DD format (ISO 8601), got: #{date}"}
    end
  end

  # Helper function to validate special hours time format
  defp validate_special_time_format(time, field) do
    case Regex.match?(~r/^([01]\d|2[0-3]):([0-5]\d)$/, time) do
      true -> :ok
      false -> {:error, field: :special_hours, message: "#{field} must be in HH:MM format (00:00 to 23:59), got: #{time}"}
    end
  end

  # Helper function to validate consistency (closed vs open/close)
  defp validate_special_hours_consistency(entry) do
    closed = Map.get(entry, "closed", false)
    open_value = Map.get(entry, "open")
    close_value = Map.get(entry, "close")

    # Check if there are non-nil time values
    has_open_time = open_value != nil
    has_close_time = close_value != nil

    cond do
      # Closed days can have nil times or no time fields at all
      closed and (has_open_time or has_close_time) ->
        {:error, field: :special_hours, message: "entry marked as closed cannot have open/close times"}

      # Open days must have both open and close times (or neither)
      not closed and (has_open_time or has_close_time) and not (has_open_time and has_close_time) ->
        {:error, field: :special_hours, message: "entry must have both open and close times, or be marked as closed"}

      true ->
        :ok
    end
  end

  calculations do
    calculate :is_open, :boolean do
      public? true
      description "Calculates whether the studio is currently open based on regular_hours, special_hours, and timezone"

      # Support optional arguments for specifying time
      argument :at, :datetime do
        allow_nil? true
      end

      calculation fn studios, context ->
        # Get the datetime to check (from argument or current time)
        check_time = case Map.get(context.arguments, :at) do
          nil -> DateTime.utc_now()
          dt -> dt
        end

        # Calculate for each studio
        Enum.map(studios, fn studio ->
          calculate_is_open(studio, check_time)
        end)
      end
    end
  end

  # Helper function to calculate if a studio is open at a given datetime
  defp calculate_is_open(studio, datetime) do
    # Get studio timezone
    timezone = studio.timezone || "America/New_York"

    # Convert UTC datetime to studio's timezone
    studio_time = DateTime.shift_zone!(datetime, timezone)

    # Get the date in the studio's timezone
    studio_date = Date.to_iso8601(DateTime.to_date(studio_time))

    # Check special hours first (they override regular hours)
    case check_special_hours(studio.special_hours, studio_date, studio_time) do
      {:special, is_open} ->
        is_open

      :no_special_hours ->
        # Fall back to regular hours
        check_regular_hours(studio.regular_hours, studio_time)
    end
  end

  # Check if there are special hours for the given date
  defp check_special_hours(special_hours, _date, _studio_time) when is_nil(special_hours) or special_hours == [] do
    :no_special_hours
  end

  defp check_special_hours(special_hours, date, studio_time) do
    # Find special hours for this date
    case Enum.find(special_hours, fn entry -> entry["date"] == date end) do
      nil ->
        :no_special_hours

      entry ->
        # If marked as closed, return false
        if Map.get(entry, "closed", false) do
          {:special, false}
        else
          # Check if open/close times are present
          if Map.has_key?(entry, "open") and Map.has_key?(entry, "close") do
            {:special, time_in_range?(studio_time, entry["open"], entry["close"])}
          else
            # No times specified, assume closed
            {:special, false}
          end
        end
    end
  end

  # Check regular hours for the given day
  defp check_regular_hours(regular_hours, _studio_time) when is_nil(regular_hours) or regular_hours == %{} do
    false
  end

  defp check_regular_hours(regular_hours, studio_time) do
    # Get the day of week (lowercase)
    day_name = studio_time |> DateTime.to_date() |> Date.day_of_week() |> day_of_week_to_name()

    # Get hours for this day
    case Map.get(regular_hours, day_name) do
      nil ->
        false

      "closed" ->
        false

      hours when is_map(hours) ->
        open_time = hours["open"]
        close_time = hours["close"]
        time_in_range?(studio_time, open_time, close_time)

      _ ->
        false
    end
  end

  # Check if a datetime is within a time range (handles overnight hours)
  defp time_in_range?(datetime, open_str, close_str) do
    current_time = {datetime.hour, datetime.minute}
    {open_hour, open_min} = parse_time(open_str)
    {close_hour, close_min} = parse_time(close_str)

    open_time = {open_hour, open_min}
    close_time = {close_hour, close_min}

    # Handle overnight hours (e.g., 22:00 to 02:00)
    if close_time < open_time do
      # Overnight: open if >= open_time OR < close_time
      current_time >= open_time or current_time < close_time
    else
      # Normal hours: open if >= open_time AND < close_time
      current_time >= open_time and current_time < close_time
    end
  end

  # Parse HH:MM string to {hour, minute} tuple
  defp parse_time(time_str) do
    [hour_str, min_str] = String.split(time_str, ":")
    {String.to_integer(hour_str), String.to_integer(min_str)}
  end

  # Convert day of week number to name
  defp day_of_week_to_name(1), do: "monday"
  defp day_of_week_to_name(2), do: "tuesday"
  defp day_of_week_to_name(3), do: "wednesday"
  defp day_of_week_to_name(4), do: "thursday"
  defp day_of_week_to_name(5), do: "friday"
  defp day_of_week_to_name(6), do: "saturday"
  defp day_of_week_to_name(7), do: "sunday"

  actions do
    defaults [:read]

    create :create do
      accept [
        :name,
        :address,
        :timezone,
        :max_capacity,
        :operating_hours,
        :regular_hours,
        :special_hours,
        :settings,
        :active,
        :organization_id
      ]
    end

    destroy :destroy do
      primary? true
      require_atomic? false
    end

    update :update do
      accept [:name, :address, :timezone, :max_capacity, :operating_hours, :regular_hours, :special_hours, :settings, :active]
      require_atomic? false
    end

    update :activate do
      accept []
      change set_attribute(:active, true)
      require_atomic? false
    end

    update :deactivate do
      accept []
      change set_attribute(:active, false)
      require_atomic? false
    end
  end

  preparations do
    # Filter studios to only those in organizations the actor is a member of
    prepare fn query, context ->
      require Ash.Query

      actor = Map.get(context, :actor)

      # Don't filter if this is a relationship load
      accessing_from = Map.get(context, :accessing_from)

      if actor && !Map.get(actor, :bypass_strict_access, false) && is_nil(accessing_from) do
        # Get actor's organization IDs from memberships
        actor_org_ids =
          case Map.get(actor, :memberships) do
            nil ->
              # Try to load memberships
              case Ash.load(actor, :memberships, domain: PilatesOnPhx.Accounts, authorize?: false) do
                {:ok, loaded_actor} ->
                  Enum.map(loaded_actor.memberships || [], & &1.organization_id)

                _ ->
                  []
              end

            memberships when is_list(memberships) ->
              Enum.map(memberships, & &1.organization_id)

            _ ->
              []
          end

        if Enum.empty?(actor_org_ids) do
          # If actor has no organizations, they can't see any studios
          Ash.Query.filter(query, false)
        else
          # Filter to studios in organizations the actor is a member of
          Ash.Query.filter(query, organization_id in ^actor_org_ids)
        end
      else
        query
      end
    end
  end

  policies do
    # Bypass authorization in test environment for fixture creation
    bypass expr(^actor(:bypass_strict_access) == true) do
      authorize_if always()
    end

    policy action_type(:read) do
      # Members can read studios in their organization (filtering done in preparations)
      authorize_if actor_present()
    end

    policy action_type(:create) do
      # Organization owners can create studios
      # Verify the actor is an owner of the organization being assigned
      authorize_if PilatesOnPhx.Studios.Studio.Checks.ActorOwnsOrganization
    end

    policy action_type([:update, :destroy]) do
      # Organization owners can manage studios
      authorize_if expr(
                     exists(
                       organization.memberships,
                       user_id == ^actor(:id) and role == :owner
                     )
                   )
    end
  end

  code_interface do
    define :create
    define :read
    define :update
    define :activate
    define :deactivate
    define :destroy
  end
end
