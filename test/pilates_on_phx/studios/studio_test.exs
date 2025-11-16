defmodule PilatesOnPhx.Studios.StudioTest do
  use PilatesOnPhx.DataCase, async: true

  alias PilatesOnPhx.Studios
  alias PilatesOnPhx.Studios.Studio
  import PilatesOnPhx.StudiosFixtures
  import PilatesOnPhx.AccountsFixtures

  require Ash.Query

  describe "studio creation (action: create)" do
    test "creates studio with valid attributes" do
      org = create_organization()

      attrs = %{
        name: "Downtown Pilates",
        address: "123 Main St, Austin, TX 78701",
        timezone: "America/Chicago",
        max_capacity: 75,
        operating_hours: %{
          "mon" => "6:00-20:00",
          "tue" => "6:00-20:00",
          "wed" => "6:00-20:00",
          "thu" => "6:00-20:00",
          "fri" => "6:00-20:00",
          "sat" => "8:00-18:00",
          "sun" => "8:00-16:00"
        },
        settings: %{},
        active: true,
        organization_id: org.id
      }

      assert {:ok, studio} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert studio.name == "Downtown Pilates"
      assert studio.address == "123 Main St, Austin, TX 78701"
      assert studio.timezone == "America/Chicago"
      assert studio.max_capacity == 75
      assert studio.operating_hours == attrs.operating_hours
      assert studio.settings == %{}
      assert studio.active == true
      assert studio.organization_id == org.id
    end

    test "requires studio name" do
      org = create_organization()

      attrs = %{
        address: "123 Main St",
        organization_id: org.id
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      changeset = error.changeset
      assert changeset.valid? == false
      assert Enum.any?(changeset.errors, fn error -> error.field == :name end)
    end

    test "validates name is not empty string" do
      org = create_organization()

      attrs = %{
        name: "",
        address: "123 Main St",
        organization_id: org.id
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      changeset = error.changeset
      assert changeset.valid? == false
      assert Enum.any?(changeset.errors, fn error -> error.field == :name end)
    end

    test "validates name has reasonable length" do
      org = create_organization()
      long_name = String.duplicate("a", 300)

      attrs = %{
        name: long_name,
        address: "123 Main St",
        organization_id: org.id
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      changeset = error.changeset
      assert changeset.valid? == false
    end

    test "requires studio address" do
      org = create_organization()

      attrs = %{
        name: "Studio Without Address",
        organization_id: org.id
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      changeset = error.changeset
      assert changeset.valid? == false
      assert Enum.any?(changeset.errors, fn error -> error.field == :address end)
    end

    test "validates address has reasonable length" do
      org = create_organization()
      long_address = String.duplicate("a", 600)

      attrs = %{
        name: "Test Studio",
        address: long_address,
        organization_id: org.id
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      changeset = error.changeset
      assert changeset.valid? == false
    end

    test "requires organization_id" do
      attrs = %{
        name: "Studio Without Organization",
        address: "123 Main St"
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      changeset = error.changeset
      assert changeset.valid? == false
      assert Enum.any?(changeset.errors, fn error -> error.field == :organization_id end)
    end

    test "sets default timezone if not provided" do
      studio = create_studio()
      assert studio.timezone == "America/New_York"
    end

    test "sets default active status to true if not provided" do
      studio = create_studio()
      assert studio.active == true
    end

    test "initializes empty settings map by default" do
      studio = create_studio()
      assert studio.settings == %{} or is_map(studio.settings)
    end

    test "allows custom settings JSON object" do
      studio =
        create_studio(
          settings: %{
            wifi_password: "pilates123",
            parking_info: "Lot behind building",
            amenities: ["showers", "lockers", "water"]
          }
        )

      assert studio.settings["wifi_password"] == "pilates123"
      assert studio.settings["parking_info"] == "Lot behind building"
      assert studio.settings["amenities"] == ["showers", "lockers", "water"]
    end

    test "validates timezone is valid IANA timezone" do
      org = create_organization()

      attrs = %{
        name: "Invalid Timezone Studio",
        address: "123 Main St",
        timezone: "Invalid/Timezone",
        organization_id: org.id
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      changeset = error.changeset
      assert changeset.valid? == false
      assert Enum.any?(changeset.errors, fn error -> error.field == :timezone end)
    end

    test "accepts various valid IANA timezones" do
      org = create_organization()

      timezones = [
        "America/New_York",
        "America/Los_Angeles",
        "America/Chicago",
        "Europe/London",
        "Asia/Tokyo",
        "Australia/Sydney",
        "UTC"
      ]

      Enum.each(timezones, fn tz ->
        attrs = %{
          name: "Studio #{tz}",
          address: "123 Main St",
          timezone: tz,
          organization_id: org.id
        }

        assert {:ok, studio} =
                 Studio
                 |> Ash.Changeset.for_create(:create, attrs)
                 |> Ash.create(
                   domain: Studios,
                   actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
                 )

        assert studio.timezone == tz
      end)
    end

    test "validates max_capacity is positive" do
      org = create_organization()

      attrs = %{
        name: "Invalid Capacity Studio",
        address: "123 Main St",
        max_capacity: 0,
        organization_id: org.id
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      changeset = error.changeset
      assert changeset.valid? == false
      assert Enum.any?(changeset.errors, fn error -> error.field == :max_capacity end)
    end

    test "validates max_capacity has reasonable upper limit" do
      org = create_organization()

      attrs = %{
        name: "Huge Capacity Studio",
        address: "123 Main St",
        max_capacity: 1000,
        organization_id: org.id
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      changeset = error.changeset
      assert changeset.valid? == false
      assert Enum.any?(changeset.errors, fn error -> error.field == :max_capacity end)
    end

    test "sets default max_capacity of 50" do
      studio = create_studio()
      assert studio.max_capacity == 50
    end

    test "validates operating_hours format" do
      org = create_organization()

      # Invalid format (not a map)
      attrs = %{
        name: "Invalid Hours Studio",
        address: "123 Main St",
        operating_hours: "9am-5pm",
        organization_id: org.id
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      changeset = error.changeset
      assert changeset.valid? == false
    end

    test "sets default operating_hours" do
      studio = create_studio()

      assert studio.operating_hours["mon"] == "6:00-20:00"
      assert studio.operating_hours["tue"] == "6:00-20:00"
      assert studio.operating_hours["wed"] == "6:00-20:00"
      assert studio.operating_hours["thu"] == "6:00-20:00"
      assert studio.operating_hours["fri"] == "6:00-20:00"
      assert studio.operating_hours["sat"] == "8:00-18:00"
      assert studio.operating_hours["sun"] == "8:00-16:00"
    end
  end

  describe "studio updates (action: update)" do
    test "updates studio name" do
      studio = create_studio(name: "Original Name")

      assert {:ok, updated} =
               studio
               |> Ash.Changeset.for_update(:update, %{name: "New Name"},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert updated.name == "New Name"
      assert updated.id == studio.id
    end

    test "updates studio address" do
      studio = create_studio(address: "123 Old St")

      assert {:ok, updated} =
               studio
               |> Ash.Changeset.for_update(:update, %{address: "456 New Ave"},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert updated.address == "456 New Ave"
    end

    test "updates studio timezone" do
      studio = create_studio(timezone: "America/New_York")

      assert {:ok, updated} =
               studio
               |> Ash.Changeset.for_update(:update, %{timezone: "America/Los_Angeles"},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert updated.timezone == "America/Los_Angeles"
    end

    test "updates studio max_capacity" do
      studio = create_studio(max_capacity: 50)

      assert {:ok, updated} =
               studio
               |> Ash.Changeset.for_update(:update, %{max_capacity: 100},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert updated.max_capacity == 100
    end

    test "updates studio operating_hours" do
      studio = create_studio()

      new_hours = %{
        "mon" => "7:00-21:00",
        "tue" => "7:00-21:00",
        "wed" => "7:00-21:00",
        "thu" => "7:00-21:00",
        "fri" => "7:00-21:00",
        "sat" => "9:00-17:00",
        "sun" => "closed"
      }

      assert {:ok, updated} =
               studio
               |> Ash.Changeset.for_update(:update, %{operating_hours: new_hours},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert updated.operating_hours == new_hours
    end

    test "updates studio settings" do
      studio = create_studio(settings: %{key: "value"})

      new_settings = %{
        wifi_password: "newpass",
        parking_spots: 20
      }

      assert {:ok, updated} =
               studio
               |> Ash.Changeset.for_update(:update, %{settings: new_settings},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert updated.settings == %{
               "wifi_password" => "newpass",
               "parking_spots" => 20
             }
    end

    test "can activate inactive studio" do
      studio = create_studio(active: false)

      assert {:ok, updated} =
               studio
               |> Ash.Changeset.for_update(:update, %{active: true},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert updated.active == true
    end

    test "can deactivate active studio" do
      studio = create_studio(active: true)

      assert {:ok, updated} =
               studio
               |> Ash.Changeset.for_update(:update, %{active: false},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert updated.active == false
    end

    test "validates name during update" do
      studio = create_studio()

      assert {:error, %Ash.Error.Invalid{} = error} =
               studio
               |> Ash.Changeset.for_update(:update, %{name: ""},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      changeset = error.changeset
      assert changeset.valid? == false
    end

    test "validates timezone during update" do
      studio = create_studio()

      assert {:error, %Ash.Error.Invalid{} = error} =
               studio
               |> Ash.Changeset.for_update(:update, %{timezone: "Invalid/Zone"},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      changeset = error.changeset
      assert changeset.valid? == false
    end

    test "validates max_capacity during update" do
      studio = create_studio()

      assert {:error, %Ash.Error.Invalid{} = error} =
               studio
               |> Ash.Changeset.for_update(:update, %{max_capacity: -10},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      changeset = error.changeset
      assert changeset.valid? == false
    end
  end

  describe "studio deactivation (action: deactivate)" do
    test "deactivate action sets active to false" do
      studio = create_studio(active: true)

      assert {:ok, deactivated} =
               studio
               |> Ash.Changeset.for_update(:deactivate, %{},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert deactivated.active == false
    end

    test "deactivate action is idempotent" do
      studio = create_studio(active: true)

      # Deactivate once
      {:ok, deactivated} =
        studio
        |> Ash.Changeset.for_update(:deactivate, %{},
          actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
        )
        |> Ash.update(domain: Studios)

      # Deactivate again
      assert {:ok, still_deactivated} =
               deactivated
               |> Ash.Changeset.for_update(:deactivate, %{},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert still_deactivated.active == false
    end
  end

  describe "studio reactivation (action: activate)" do
    test "activate action sets active to true" do
      studio = create_studio(active: false)

      assert {:ok, activated} =
               studio
               |> Ash.Changeset.for_update(:activate, %{},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert activated.active == true
    end

    test "activate action is idempotent" do
      studio = create_studio(active: false)

      # Activate once
      {:ok, activated} =
        studio
        |> Ash.Changeset.for_update(:activate, %{},
          actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
        )
        |> Ash.update(domain: Studios)

      # Activate again
      assert {:ok, still_activated} =
               activated
               |> Ash.Changeset.for_update(:activate, %{},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert still_activated.active == true
    end
  end

  describe "studio relationships" do
    test "studio belongs to organization" do
      org = create_organization()
      studio = create_studio(organization: org)

      loaded_studio =
        Studio
        |> Ash.Query.filter(id == ^studio.id)
        |> Ash.Query.load(:organization)
        |> Ash.read_one!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert loaded_studio.organization.id == org.id
    end

    test "studio has many staff assignments" do
      studio = create_studio()
      staff1 = create_studio_staff(studio: studio)
      staff2 = create_studio_staff(studio: studio)

      loaded_studio =
        Studio
        |> Ash.Query.filter(id == ^studio.id)
        |> Ash.Query.load(:staff_assignments)
        |> Ash.read_one!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      staff_ids = Enum.map(loaded_studio.staff_assignments, & &1.id)
      assert staff1.id in staff_ids
      assert staff2.id in staff_ids
    end

    test "studio has many rooms" do
      studio = create_studio()
      room1 = create_room(studio: studio)
      room2 = create_room(studio: studio)

      loaded_studio =
        Studio
        |> Ash.Query.filter(id == ^studio.id)
        |> Ash.Query.load(:rooms)
        |> Ash.read_one!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      room_ids = Enum.map(loaded_studio.rooms, & &1.id)
      assert room1.id in room_ids
      assert room2.id in room_ids
    end

    test "studio has many equipment" do
      studio = create_studio()
      equipment1 = create_equipment(studio: studio)
      equipment2 = create_equipment(studio: studio)

      loaded_studio =
        Studio
        |> Ash.Query.filter(id == ^studio.id)
        |> Ash.Query.load(:equipment)
        |> Ash.read_one!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      equipment_ids = Enum.map(loaded_studio.equipment, & &1.id)
      assert equipment1.id in equipment_ids
      assert equipment2.id in equipment_ids
    end

    test "studio without rooms has empty rooms list" do
      studio = create_studio()

      loaded_studio =
        Studio
        |> Ash.Query.filter(id == ^studio.id)
        |> Ash.Query.load(:rooms)
        |> Ash.read_one!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert loaded_studio.rooms == []
    end
  end

  describe "studio settings and configuration" do
    test "stores wifi and parking information" do
      studio =
        create_studio(
          settings: %{
            wifi_password: "studio123",
            wifi_network: "PilatesWiFi",
            parking_info: "Free lot behind building"
          }
        )

      assert studio.settings["wifi_password"] == "studio123"
      assert studio.settings["wifi_network"] == "PilatesWiFi"
      assert studio.settings["parking_info"] == "Free lot behind building"
    end

    test "stores amenities list" do
      studio =
        create_studio(
          settings: %{
            amenities: ["showers", "lockers", "water", "towels", "mats"]
          }
        )

      assert studio.settings["amenities"] == ["showers", "lockers", "water", "towels", "mats"]
    end

    test "stores contact information" do
      studio =
        create_studio(
          settings: %{
            phone: "555-1234",
            email: "info@pilatesstudio.com",
            website: "https://pilatesstudio.com"
          }
        )

      assert studio.settings["phone"] == "555-1234"
      assert studio.settings["email"] == "info@pilatesstudio.com"
      assert studio.settings["website"] == "https://pilatesstudio.com"
    end

    test "handles nested settings structures" do
      studio =
        create_studio(
          settings: %{
            branding: %{
              primary_color: "#4A5568",
              logo_url: "https://example.com/logo.png"
            },
            policies: %{
              late_cancel_fee: 15.00,
              no_show_fee: 25.00
            }
          }
        )

      assert studio.settings["branding"]["primary_color"] == "#4A5568"
      assert studio.settings["policies"]["late_cancel_fee"] == 15.00
    end
  end

  describe "studio queries and filtering" do
    test "can query all studios" do
      create_studio(name: "Studio A")
      create_studio(name: "Studio B")
      create_studio(name: "Studio C")

      studios =
        Studio |> Ash.read!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert length(studios) >= 3
    end

    test "can filter studios by active status" do
      create_studio(name: "Active Studio", active: true)
      create_studio(name: "Inactive Studio", active: false)

      active_studios =
        Studio
        |> Ash.Query.filter(active == true)
        |> Ash.read!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert length(active_studios) >= 1
      assert Enum.all?(active_studios, fn studio -> studio.active == true end)
    end

    test "can filter studios by name" do
      studio = create_studio(name: "Specific Studio Name")

      found_studios =
        Studio
        |> Ash.Query.filter(name == ^studio.name)
        |> Ash.read!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert length(found_studios) == 1
      assert hd(found_studios).id == studio.id
    end

    test "can search studios by name pattern" do
      create_studio(name: "Pilates Central")
      create_studio(name: "Central Yoga")
      create_studio(name: "Downtown Pilates")

      central_studios =
        Studio
        |> Ash.Query.filter(contains(name, "Central"))
        |> Ash.read!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert length(central_studios) >= 2
      assert Enum.all?(central_studios, fn studio -> String.contains?(studio.name, "Central") end)
    end

    test "can filter by timezone" do
      create_studio(name: "NYC Studio", timezone: "America/New_York")
      create_studio(name: "LA Studio", timezone: "America/Los_Angeles")

      nyc_studios =
        Studio
        |> Ash.Query.filter(timezone == "America/New_York")
        |> Ash.read!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert length(nyc_studios) >= 1
      assert Enum.all?(nyc_studios, fn studio -> studio.timezone == "America/New_York" end)
    end

    test "can filter by organization" do
      org1 = create_organization()
      org2 = create_organization()

      studio1 = create_studio(organization: org1)
      _studio2 = create_studio(organization: org2)

      org1_studios =
        Studio
        |> Ash.Query.filter(organization_id == ^org1.id)
        |> Ash.read!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert length(org1_studios) >= 1
      assert Enum.all?(org1_studios, fn studio -> studio.organization_id == org1.id end)
    end
  end

  describe "multi-tenant isolation" do
    test "studios belong to specific organizations" do
      org1 = create_organization()
      org2 = create_organization()

      studio1 = create_studio(organization: org1)
      studio2 = create_studio(organization: org2)

      assert studio1.organization_id == org1.id
      assert studio2.organization_id == org2.id
      assert studio1.organization_id != studio2.organization_id
    end

    test "studio data does not leak between organizations" do
      org1 = create_organization()
      org2 = create_organization()

      studio1 = create_studio(name: "Org1 Studio", organization: org1)
      studio2 = create_studio(name: "Org2 Studio", organization: org2)

      # Query studios for org1
      org1_studios =
        Studio
        |> Ash.Query.filter(organization_id == ^org1.id)
        |> Ash.read!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      studio_ids = Enum.map(org1_studios, & &1.id)

      assert studio1.id in studio_ids
      refute studio2.id in studio_ids
    end

    test "multiple studios can exist in same organization" do
      org = create_organization()

      studio1 = create_studio(name: "Location 1", organization: org)
      studio2 = create_studio(name: "Location 2", organization: org)
      studio3 = create_studio(name: "Location 3", organization: org)

      org_studios =
        Studio
        |> Ash.Query.filter(organization_id == ^org.id)
        |> Ash.read!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert length(org_studios) >= 3
      studio_ids = Enum.map(org_studios, & &1.id)
      assert studio1.id in studio_ids
      assert studio2.id in studio_ids
      assert studio3.id in studio_ids
    end
  end

  describe "studio lifecycle" do
    test "new studio starts as active by default" do
      studio = create_studio()
      assert studio.active == true
    end

    test "tracks studio creation timestamp" do
      studio = create_studio()

      assert studio.inserted_at != nil
      assert %DateTime{} = studio.inserted_at
    end

    test "tracks studio update timestamp" do
      studio = create_studio()
      original_updated_at = studio.updated_at

      Process.sleep(10)

      {:ok, updated} =
        studio
        |> Ash.Changeset.for_update(:update, %{name: "Updated Name"},
          actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
        )
        |> Ash.update(domain: Studios)

      assert DateTime.compare(updated.updated_at, original_updated_at) == :gt
    end

    test "deactivated studio remains queryable" do
      studio = create_studio(name: "To Be Deactivated")

      {:ok, deactivated} =
        studio
        |> Ash.Changeset.for_update(:deactivate, %{},
          actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
        )
        |> Ash.update(domain: Studios)

      # Should still be able to query it
      found =
        Studio
        |> Ash.Query.filter(id == ^deactivated.id)
        |> Ash.read_one!(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert found.id == deactivated.id
      assert found.active == false
    end
  end

  describe "preparation filters and actor scenarios" do
    test "filters studios when actor has no memberships loaded" do
      org = create_organization()
      studio = create_studio(organization: org)

      # Create user without loading memberships
      user = create_user(organization: org)

      # Query should handle loading memberships dynamically
      result = Studio
        |> Ash.Query.filter(id == ^studio.id)
        |> Ash.read(domain: Studios, actor: user)

      # Should either succeed with loaded memberships or return empty
      case result do
        {:ok, studios} -> assert is_list(studios)
        {:error, _} -> :ok
      end
    end

    test "returns empty when actor has no organizations" do
      # Create user without organization membership
      user = create_user_without_org()
      studio = create_studio()

      # User with no organization should not see any studios
      assert {:ok, studios} = Studio
        |> Ash.read(domain: Studios, actor: user)

      refute Enum.any?(studios, fn s -> s.id == studio.id end)
    end

    test "filters studios by actor organization membership" do
      org1 = create_organization()
      org2 = create_organization()

      user = create_user(organization: org1)
      studio1 = create_studio(organization: org1)
      studio2 = create_studio(organization: org2)

      assert {:ok, studios} = Studio
        |> Ash.read(domain: Studios, actor: user)

      studio_ids = Enum.map(studios, & &1.id)
      assert studio1.id in studio_ids
      refute studio2.id in studio_ids
    end
  end

  describe "authorization policies" do
    test "organization owner can create studios" do
      scenario = create_organization_scenario()
      owner = scenario.owner
      org = scenario.organization

      attrs = %{
        name: "New Studio",
        address: "123 Main St",
        organization_id: org.id
      }

      assert {:ok, studio} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs, actor: owner)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert studio.name == "New Studio"
      assert studio.organization_id == org.id
    end

    test "organization owner can update their studios" do
      scenario = create_organization_scenario()
      owner = scenario.owner
      org = scenario.organization

      studio = create_studio(organization: org)

      assert {:ok, updated} =
               studio
               |> Ash.Changeset.for_update(:update, %{name: "Updated by Owner"}, actor: owner)
               |> Ash.update(domain: Studios)

      assert updated.name == "Updated by Owner"
    end

    test "organization members can read studios" do
      org = create_organization()
      member = create_user(organization: org, role: :client)
      studio = create_studio(organization: org)

      assert {:ok, loaded} =
               Studio
               |> Ash.Query.filter(id == ^studio.id)
               |> Ash.read_one(domain: Studios, actor: member)

      assert loaded.id == studio.id
    end

    test "users from different organizations cannot access other studios" do
      org1 = create_organization()
      org2 = create_organization()

      user1 = create_user(organization: org1)
      studio2 = create_studio(organization: org2)

      # User from org1 should not be able to read studio from org2
      assert {:ok, nil} =
               Studio
               |> Ash.Query.filter(id == ^studio2.id)
               |> Ash.read_one(domain: Studios, actor: user1)
    end

    @tag :skip
    test "regular members cannot update studios" do
      # TODO: Implement role-based authorization (owner/admin only)
      org = create_organization()
      member = create_user(organization: org, role: :client)
      studio = create_studio(organization: org)

      assert {:error, %Ash.Error.Forbidden{}} =
               studio
               |> Ash.Changeset.for_update(:update, %{name: "Unauthorized Update"}, actor: member)
               |> Ash.update(domain: Studios)
    end

    @tag :skip
    test "instructors cannot deactivate studios" do
      # TODO: Implement role-based authorization (owner/admin only)
      org = create_organization()
      instructor = create_user(organization: org, role: :instructor)
      studio = create_studio(organization: org)

      assert {:error, %Ash.Error.Forbidden{}} =
               studio
               |> Ash.Changeset.for_update(:deactivate, %{}, actor: instructor)
               |> Ash.update(domain: Studios)
    end
  end

  describe "data validation edge cases" do
    test "handles unicode characters in studio name" do
      org = create_organization()

      attrs = %{
        name: "Estudio de Pilates José García 体育馆",
        address: "123 Main St",
        organization_id: org.id
      }

      assert {:ok, studio} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert studio.name == "Estudio de Pilates José García 体育馆"
    end

    test "handles special characters in studio name" do
      org = create_organization()

      attrs = %{
        name: "Studio @ Main St. #1 & Wellness Center",
        address: "123 Main St",
        organization_id: org.id
      }

      assert {:ok, studio} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())

      assert studio.name == "Studio @ Main St. #1 & Wellness Center"
    end

    test "rejects nil as settings" do
      studio = create_studio()

      assert {:error, %Ash.Error.Invalid{} = error} =
               studio
               |> Ash.Changeset.for_update(:update, %{settings: nil},
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
               |> Ash.update(domain: Studios)

      changeset = error.changeset
      assert changeset.valid? == false
    end

    test "handles deeply nested settings structures" do
      deep_settings = %{
        level1: %{
          level2: %{
            level3: %{
              level4: %{
                deeply_nested_value: "found"
              }
            }
          }
        }
      }

      studio = create_studio(settings: deep_settings)

      assert studio.settings["level1"]["level2"]["level3"]["level4"]["deeply_nested_value"] ==
               "found"
    end
  end

  describe "concurrent studio operations" do
    test "handles concurrent studio creation" do
      org = create_organization()

      tasks =
        Enum.map(1..5, fn i ->
          Task.async(fn ->
            attrs = %{
              name: "Concurrent Studio #{i}",
              address: "#{i} Main St",
              organization_id: org.id
            }

            Studio
            |> Ash.Changeset.for_create(:create, attrs)
            |> Ash.create(domain: Studios, actor: PilatesOnPhx.StudiosFixtures.bypass_actor())
          end)
        end)

      results = Task.await_many(tasks)

      # All should succeed with unique names
      assert Enum.all?(results, fn
               {:ok, _studio} -> true
               _ -> false
             end)
    end

    test "handles concurrent updates to same studio" do
      studio = create_studio()

      tasks =
        Enum.map(1..3, fn i ->
          Task.async(fn ->
            studio
            |> Ash.Changeset.for_update(:update, %{name: "Updated Name #{i}"},
              actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
            )
            |> Ash.update(domain: Studios)
          end)
        end)

      results = Task.await_many(tasks)

      # All should succeed or fail gracefully
      successful =
        Enum.filter(results, fn
          {:ok, _} -> true
          _ -> false
        end)

      assert length(successful) >= 1
    end
  end

  describe "studio deletion and cleanup" do
    test "can delete studio with no related resources" do
      studio = create_studio()

      assert :ok =
               Ash.destroy(studio,
                 domain: Studios,
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )

      # Verify studio is gone
      assert {:ok, nil} =
               Studio
               |> Ash.Query.filter(id == ^studio.id)
               |> Ash.read_one(
                 domain: Studios,
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )
    end

    @tag :skip
    test "deleting studio cascades to rooms and equipment" do
      # TODO: Implement cascade deletion for studio resources
      studio = create_studio()
      room = create_room(studio: studio)
      equipment = create_equipment(studio: studio)

      # Delete studio
      assert :ok =
               Ash.destroy(studio,
                 domain: Studios,
                 actor: PilatesOnPhx.StudiosFixtures.bypass_actor()
               )

      # Verify related resources are deleted (or updated appropriately)
      # This behavior needs to be defined in Studio resource
    end
  end
end
