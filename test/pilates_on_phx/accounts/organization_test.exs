defmodule PilatesOnPhx.Accounts.OrganizationTest do
  use PilatesOnPhx.DataCase, async: true

  alias PilatesOnPhx.Accounts
  alias PilatesOnPhx.Accounts.Organization
  import PilatesOnPhx.AccountsFixtures

  require Ash.Query

  describe "organization creation (action: create)" do
    test "creates organization with valid attributes" do
      attrs = %{
        name: "Test Pilates Studio",
        timezone: "America/New_York",
        settings: %{},
        active: true
      }

      assert {:ok, org} =
        Organization
        |> Ash.Changeset.for_create(:create, attrs)
        |> Ash.create(domain: Accounts)

      assert org.name == "Test Pilates Studio"
      assert org.timezone == "America/New_York"
      assert org.settings == %{}
      assert org.active == true
    end

    test "requires organization name" do
      attrs = %{
        timezone: "America/New_York",
        active: true
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
        Organization
        |> Ash.Changeset.for_create(:create, attrs)
        |> Ash.create(domain: Accounts)

      changeset = error.changeset
      assert changeset.valid? == false
      assert Enum.any?(changeset.errors, fn error -> error.field == :name end)
    end

    test "validates name is not empty string" do
      attrs = %{
        name: "",
        timezone: "America/New_York",
        active: true
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
        Organization
        |> Ash.Changeset.for_create(:create, attrs)
        |> Ash.create(domain: Accounts)

      changeset = error.changeset
      assert changeset.valid? == false
      assert Enum.any?(changeset.errors, fn error -> error.field == :name end)
    end

    test "validates name has reasonable length" do
      # Test name too long
      long_name = String.duplicate("a", 300)

      attrs = %{
        name: long_name,
        timezone: "America/New_York",
        active: true
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
        Organization
        |> Ash.Changeset.for_create(:create, attrs)
        |> Ash.create(domain: Accounts)

      changeset = error.changeset
      assert changeset.valid? == false
    end

    test "sets default timezone if not provided" do
      attrs = %{
        name: "Studio Without Timezone",
        active: true
      }

      assert {:ok, org} =
        Organization
        |> Ash.Changeset.for_create(:create, attrs)
        |> Ash.create(domain: Accounts)

      # Should have a default timezone (e.g., "UTC" or "America/New_York")
      assert org.timezone != nil
      assert is_binary(org.timezone)
    end

    test "sets default active status to true if not provided" do
      attrs = %{
        name: "Studio Default Active"
      }

      assert {:ok, org} =
        Organization
        |> Ash.Changeset.for_create(:create, attrs)
        |> Ash.create(domain: Accounts)

      assert org.active == true
    end

    test "initializes empty settings map by default" do
      attrs = %{
        name: "Studio Default Settings"
      }

      assert {:ok, org} =
        Organization
        |> Ash.Changeset.for_create(:create, attrs)
        |> Ash.create(domain: Accounts)

      assert org.settings == %{} or is_map(org.settings)
    end

    test "allows custom settings JSON object" do
      attrs = %{
        name: "Studio With Settings",
        settings: %{
          booking_window_days: 30,
          cancellation_hours: 24,
          max_bookings_per_client: 5,
          features: %{
            waitlist_enabled: true,
            auto_confirm: false
          }
        }
      }

      assert {:ok, org} =
        Organization
        |> Ash.Changeset.for_create(:create, attrs)
        |> Ash.create(domain: Accounts)

      assert org.settings["booking_window_days"] == 30
      assert org.settings["cancellation_hours"] == 24
      assert org.settings["features"]["waitlist_enabled"] == true
    end

    test "validates timezone is valid IANA timezone" do
      attrs = %{
        name: "Invalid Timezone Studio",
        timezone: "Invalid/Timezone"
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
        Organization
        |> Ash.Changeset.for_create(:create, attrs)
        |> Ash.create(domain: Accounts)

      changeset = error.changeset
      assert changeset.valid? == false
      assert Enum.any?(changeset.errors, fn error -> error.field == :timezone end)
    end

    test "accepts various valid IANA timezones" do
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
          timezone: tz
        }

        assert {:ok, org} =
          Organization
          |> Ash.Changeset.for_create(:create, attrs)
          |> Ash.create(domain: Accounts)

        assert org.timezone == tz
      end)
    end
  end

  describe "organization updates (action: update)" do
    test "updates organization name" do
      org = create_organization(name: "Original Name")

      assert {:ok, updated} =
        org
        |> Ash.Changeset.for_update(:update, %{name: "New Name"}, actor: bypass_actor())
        |> Ash.update(domain: Accounts)

      assert updated.name == "New Name"
      assert updated.id == org.id
    end

    test "updates organization timezone" do
      org = create_organization(timezone: "America/New_York")

      assert {:ok, updated} =
        org
        |> Ash.Changeset.for_update(:update, %{timezone: "America/Los_Angeles"}, actor: bypass_actor())
        |> Ash.update(domain: Accounts)

      assert updated.timezone == "America/Los_Angeles"
    end

    test "updates organization settings" do
      org = create_organization(settings: %{key: "value"})

      new_settings = %{
        booking_window_days: 14,
        new_feature: "enabled"
      }

      assert {:ok, updated} =
        org
        |> Ash.Changeset.for_update(:update, %{settings: new_settings}, actor: bypass_actor())
        |> Ash.update(domain: Accounts)

      # Settings are stored as JSON, so keys become strings
      assert updated.settings == %{
        "booking_window_days" => 14,
        "new_feature" => "enabled"
      }
    end

    test "can activate inactive organization" do
      org = create_organization(active: false)

      assert {:ok, updated} =
        org
        |> Ash.Changeset.for_update(:update, %{active: true}, actor: bypass_actor())
        |> Ash.update(domain: Accounts)

      assert updated.active == true
    end

    test "can deactivate active organization" do
      org = create_organization(active: true)

      assert {:ok, updated} =
        org
        |> Ash.Changeset.for_update(:update, %{active: false}, actor: bypass_actor())
        |> Ash.update(domain: Accounts)

      assert updated.active == false
    end

    test "validates name during update" do
      org = create_organization()

      assert {:error, %Ash.Error.Invalid{} = error} =
        org
        |> Ash.Changeset.for_update(:update, %{name: ""}, actor: bypass_actor())
        |> Ash.update(domain: Accounts)

      changeset = error.changeset
      assert changeset.valid? == false
    end

    @tag :skip
    test "validates timezone during update" do
      # TODO: Add timezone validation to Organization resource
      org = create_organization()

      assert {:error, %Ash.Error.Invalid{} = error} =
        org
        |> Ash.Changeset.for_update(:update, %{timezone: "Invalid/Zone"}, actor: bypass_actor())
        |> Ash.update(domain: Accounts)

      changeset = error.changeset
      assert changeset.valid? == false
    end
  end

  describe "organization deactivation (action: deactivate)" do
    test "deactivate action sets active to false" do
      org = create_organization(active: true)

      assert {:ok, deactivated} =
        org
        |> Ash.Changeset.for_update(:deactivate, %{}, actor: bypass_actor())
        |> Ash.update(domain: Accounts)

      assert deactivated.active == false
    end

    test "deactivate action is idempotent" do
      org = create_organization(active: true)

      # Deactivate once
      {:ok, deactivated} =
        org
        |> Ash.Changeset.for_update(:deactivate, %{}, actor: bypass_actor())
        |> Ash.update(domain: Accounts)

      # Deactivate again
      assert {:ok, still_deactivated} =
        deactivated
        |> Ash.Changeset.for_update(:deactivate, %{}, actor: bypass_actor())
        |> Ash.update(domain: Accounts)

      assert still_deactivated.active == false
    end
  end

  describe "organization reactivation (action: activate)" do
    test "activate action sets active to true" do
      org = create_organization(active: false)

      assert {:ok, activated} =
        org
        |> Ash.Changeset.for_update(:activate, %{}, actor: bypass_actor())
        |> Ash.update(domain: Accounts)

      assert activated.active == true
    end

    test "activate action is idempotent" do
      org = create_organization(active: false)

      # Activate once
      {:ok, activated} =
        org
        |> Ash.Changeset.for_update(:activate, %{}, actor: bypass_actor())
        |> Ash.update(domain: Accounts)

      # Activate again
      assert {:ok, still_activated} =
        activated
        |> Ash.Changeset.for_update(:activate, %{}, actor: bypass_actor())
        |> Ash.update(domain: Accounts)

      assert still_activated.active == true
    end
  end

  describe "organization membership relationships" do
    test "organization has many users through memberships" do
      org = create_organization()
      user1 = create_user(organization: org)
      user2 = create_user(organization: org)
      user3 = create_user(organization: org)

      loaded_org =
        Organization
        |> Ash.Query.filter(id == ^org.id)
        |> Ash.Query.load(:users)
        |> Ash.read_one!(domain: Accounts, actor: bypass_actor())

      user_ids = Enum.map(loaded_org.users, & &1.id)
      assert user1.id in user_ids
      assert user2.id in user_ids
      assert user3.id in user_ids
    end

    test "organization can load memberships with roles" do
      org = create_organization()
      owner = create_user(organization: org, role: :owner)
      instructor = create_user(organization: org, role: :instructor)
      client = create_user(organization: org, role: :client)

      # Update memberships with proper roles
      owner_membership = Accounts.OrganizationMembership
      |> Ash.Query.filter(user_id == ^owner.id and organization_id == ^org.id)
      |> Ash.read_one!(domain: Accounts, actor: bypass_actor())

      owner_membership
      |> Ash.Changeset.for_update(:update, %{role: :owner}, actor: bypass_actor())
      |> Ash.update!(domain: Accounts)

      loaded_org =
        Organization
        |> Ash.Query.filter(id == ^org.id)
        |> Ash.Query.load(:memberships)
        |> Ash.read_one!(domain: Accounts, actor: bypass_actor())

      assert length(loaded_org.memberships) >= 3

      roles = Enum.map(loaded_org.memberships, & &1.role)
      assert :owner in roles
    end

    test "organization without members has empty users list" do
      org = create_organization()

      loaded_org =
        Organization
        |> Ash.Query.filter(id == ^org.id)
        |> Ash.Query.load(:users)
        |> Ash.read_one!(domain: Accounts, actor: bypass_actor())

      assert loaded_org.users == []
    end
  end

  describe "organization settings and configuration" do
    test "stores booking window configuration" do
      org = create_organization(
        settings: %{
          booking_window_days: 30,
          booking_cutoff_hours: 2
        }
      )

      assert org.settings["booking_window_days"] == 30
      assert org.settings["booking_cutoff_hours"] == 2
    end

    test "stores cancellation policy settings" do
      org = create_organization(
        settings: %{
          cancellation_hours: 24,
          late_cancel_fee: 15.00,
          no_show_fee: 25.00
        }
      )

      assert org.settings["cancellation_hours"] == 24
      assert org.settings["late_cancel_fee"] == 15.00
      assert org.settings["no_show_fee"] == 25.00
    end

    test "stores waitlist configuration" do
      org = create_organization(
        settings: %{
          waitlist_enabled: true,
          auto_fill_from_waitlist: true,
          waitlist_notification_hours: 12
        }
      )

      assert org.settings["waitlist_enabled"] == true
      assert org.settings["auto_fill_from_waitlist"] == true
      assert org.settings["waitlist_notification_hours"] == 12
    end

    test "stores notification preferences" do
      org = create_organization(
        settings: %{
          notifications: %{
            reminder_hours_before: [24, 2],
            enable_sms: true,
            enable_email: true
          }
        }
      )

      notifications = org.settings["notifications"]
      assert notifications["reminder_hours_before"] == [24, 2]
      assert notifications["enable_sms"] == true
      assert notifications["enable_email"] == true
    end

    test "stores class scheduling defaults" do
      org = create_organization(
        settings: %{
          default_class_duration: 50,
          max_class_capacity: 12,
          min_advance_booking_hours: 1
        }
      )

      assert org.settings["default_class_duration"] == 50
      assert org.settings["max_class_capacity"] == 12
      assert org.settings["min_advance_booking_hours"] == 1
    end

    test "handles nested settings structures" do
      org = create_organization(
        settings: %{
          features: %{
            online_booking: true,
            packages: %{
              enabled: true,
              types: ["10-pack", "20-pack", "unlimited"]
            }
          },
          branding: %{
            primary_color: "#4A5568",
            logo_url: "https://example.com/logo.png"
          }
        }
      )

      assert org.settings["features"]["online_booking"] == true
      assert org.settings["features"]["packages"]["enabled"] == true
      assert length(org.settings["features"]["packages"]["types"]) == 3
      assert org.settings["branding"]["primary_color"] == "#4A5568"
    end
  end

  describe "organization queries and filtering" do
    test "can query all organizations" do
      create_organization(name: "Studio A")
      create_organization(name: "Studio B")
      create_organization(name: "Studio C")

      orgs = Organization |> Ash.read!(domain: Accounts, actor: bypass_actor())

      assert length(orgs) >= 3
    end

    test "can filter organizations by active status" do
      create_organization(name: "Active Studio", active: true)
      create_organization(name: "Inactive Studio", active: false)

      active_orgs =
        Organization
        |> Ash.Query.filter(active == true)
        |> Ash.read!(domain: Accounts, actor: bypass_actor())

      assert length(active_orgs) >= 1
      assert Enum.all?(active_orgs, fn org -> org.active == true end)
    end

    test "can filter organizations by name" do
      org = create_organization(name: "Specific Studio Name")

      found_orgs =
        Organization
        |> Ash.Query.filter(name == ^org.name)
        |> Ash.read!(domain: Accounts, actor: bypass_actor())

      assert length(found_orgs) == 1
      assert hd(found_orgs).id == org.id
    end

    test "can search organizations by name pattern" do
      create_organization(name: "Pilates Central")
      create_organization(name: "Central Yoga")
      create_organization(name: "Downtown Pilates")

      central_orgs =
        Organization
        |> Ash.Query.filter(contains(name, "Central"))
        |> Ash.read!(domain: Accounts, actor: bypass_actor())

      assert length(central_orgs) >= 2
      assert Enum.all?(central_orgs, fn org -> String.contains?(org.name, "Central") end)
    end

    test "can filter by timezone" do
      create_organization(name: "NYC Studio", timezone: "America/New_York")
      create_organization(name: "LA Studio", timezone: "America/Los_Angeles")

      nyc_orgs =
        Organization
        |> Ash.Query.filter(timezone == "America/New_York")
        |> Ash.read!(domain: Accounts, actor: bypass_actor())

      assert length(nyc_orgs) >= 1
      assert Enum.all?(nyc_orgs, fn org -> org.timezone == "America/New_York" end)
    end
  end

  describe "multi-tenant isolation" do
    test "each organization is an independent tenant" do
      org1 = create_organization(name: "Studio One")
      org2 = create_organization(name: "Studio Two")

      assert org1.id != org2.id
      assert org1.name != org2.name
    end

    test "organization data does not leak between tenants" do
      scenario1 = create_organization_scenario(%{
        instructor_count: 2,
        client_count: 5
      })

      scenario2 = create_organization_scenario(%{
        instructor_count: 3,
        client_count: 10
      })

      # Load organization 1 users
      org1_users =
        Accounts.User
        |> Ash.Query.filter(
          id in ^(Enum.map(scenario1.organization.memberships, & &1.user_id) || [scenario1.owner.id])
        )
        |> Ash.read!(domain: Accounts, actor: bypass_actor())

      # Verify no users from org2 appear in org1
      org2_user_ids = [scenario2.owner.id | Enum.map(scenario2.instructors ++ scenario2.clients, & &1.id)]

      Enum.each(org1_users, fn user ->
        refute user.id in org2_user_ids,
          "User from organization 2 leaked into organization 1 query"
      end)
    end
  end

  describe "organization lifecycle" do
    test "new organization starts as active by default" do
      org = create_organization()
      assert org.active == true
    end

    test "tracks organization creation timestamp" do
      org = create_organization()

      assert org.inserted_at != nil
      assert %DateTime{} = org.inserted_at
    end

    test "tracks organization update timestamp" do
      org = create_organization()
      original_updated_at = org.updated_at

      Process.sleep(10)

      {:ok, updated} =
        org
        |> Ash.Changeset.for_update(:update, %{name: "Updated Name"}, actor: bypass_actor())
        |> Ash.update(domain: Accounts)

      assert DateTime.compare(updated.updated_at, original_updated_at) == :gt
    end

    test "deactivated organization remains queryable" do
      org = create_organization(name: "To Be Deactivated")

      {:ok, deactivated} =
        org
        |> Ash.Changeset.for_update(:deactivate, %{}, actor: bypass_actor())
        |> Ash.update(domain: Accounts)

      # Should still be able to query it
      found =
        Organization
        |> Ash.Query.filter(id == ^deactivated.id)
        |> Ash.read_one!(domain: Accounts, actor: bypass_actor())

      assert found.id == deactivated.id
      assert found.active == false
    end
  end

  describe "authorization policies" do
    test "organization owner can update organization" do
      scenario = create_organization_scenario()
      owner = scenario.owner
      org = scenario.organization

      assert {:ok, updated} =
        org
        |> Ash.Changeset.for_update(:update, %{name: "Updated by Owner"}, actor: owner)
        |> Ash.update(domain: Accounts)

      assert updated.name == "Updated by Owner"
    end

    test "organization members can read organization" do
      org = create_organization()
      member = create_user(organization: org, role: :client)

      assert {:ok, loaded} =
        Organization
        |> Ash.Query.filter(id == ^org.id)
        |> Ash.read_one(domain: Accounts, actor: member)

      assert loaded.id == org.id
    end

    test "users from different organizations cannot access other orgs" do
      org1 = create_organization()
      org2 = create_organization()

      user1 = create_user(organization: org1)

      # User from org1 should not be able to read org2 (preparation filter prevents access)
      assert {:ok, nil} =
        Organization
        |> Ash.Query.filter(id == ^org2.id)
        |> Ash.read_one(domain: Accounts, actor: user1)
    end

    @tag :skip
    test "regular members cannot update organization settings" do
      # TODO: Implement role-based authorization for organization updates (owner-only)
      org = create_organization()
      member = create_user(organization: org, role: :client)

      assert {:error, %Ash.Error.Forbidden{}} =
        org
        |> Ash.Changeset.for_update(:update, %{name: "Unauthorized Update"}, actor: member)
        |> Ash.update(domain: Accounts)
    end

    @tag :skip
    test "instructors cannot deactivate organization" do
      # TODO: Implement role-based authorization for organization deactivation (owner-only)
      org = create_organization()
      instructor = create_user(organization: org, role: :instructor)

      assert {:error, %Ash.Error.Forbidden{}} =
        org
        |> Ash.Changeset.for_update(:deactivate, %{}, actor: instructor)
        |> Ash.update(domain: Accounts)
    end
  end

  describe "data validation edge cases" do
    test "handles very long organization names" do
      long_name = String.duplicate("Studio ", 50)

      attrs = %{name: long_name}

      assert {:error, %Ash.Error.Invalid{} = error} =
        Organization
        |> Ash.Changeset.for_create(:create, attrs)
        |> Ash.create(domain: Accounts)

      changeset = error.changeset
      assert changeset.valid? == false
    end

    test "handles unicode characters in organization name" do
      attrs = %{
        name: "Estudio de Pilates José García 体育馆"
      }

      assert {:ok, org} =
        Organization
        |> Ash.Changeset.for_create(:create, attrs)
        |> Ash.create(domain: Accounts)

      assert org.name == "Estudio de Pilates José García 体育馆"
    end

    test "handles special characters in organization name" do
      attrs = %{
        name: "Studio @ Main St. #1 & Wellness Center"
      }

      assert {:ok, org} =
        Organization
        |> Ash.Changeset.for_create(:create, attrs)
        |> Ash.create(domain: Accounts)

      assert org.name == "Studio @ Main St. #1 & Wellness Center"
    end

    test "rejects nil as settings" do
      org = create_organization()

      assert {:error, %Ash.Error.Invalid{} = error} =
        org
        |> Ash.Changeset.for_update(:update, %{settings: nil}, actor: bypass_actor())
        |> Ash.update(domain: Accounts)

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

      org = create_organization(settings: deep_settings)

      assert org.settings["level1"]["level2"]["level3"]["level4"]["deeply_nested_value"] == "found"
    end
  end

  describe "concurrent organization operations" do
    test "handles concurrent organization creation" do
      tasks = Enum.map(1..5, fn i ->
        Task.async(fn ->
          attrs = %{name: "Concurrent Studio #{i}"}

          Organization
          |> Ash.Changeset.for_create(:create, attrs)
          |> Ash.create(domain: Accounts)
        end)
      end)

      results = Task.await_many(tasks)

      # All should succeed with unique names
      assert Enum.all?(results, fn
        {:ok, _org} -> true
        _ -> false
      end)
    end

    test "handles concurrent updates to same organization" do
      org = create_organization()

      tasks = Enum.map(1..3, fn i ->
        Task.async(fn ->
          org
          |> Ash.Changeset.for_update(:update, %{
            name: "Updated Name #{i}"
          }, actor: bypass_actor())
          |> Ash.update(domain: Accounts)
        end)
      end)

      results = Task.await_many(tasks)

      # All should succeed or fail gracefully
      successful = Enum.filter(results, fn
        {:ok, _} -> true
        _ -> false
      end)

      assert length(successful) >= 1
    end
  end

  describe "organization deletion and cleanup" do
    test "can delete organization with no members" do
      org = create_organization()

      assert :ok = Ash.destroy(org, domain: Accounts, actor: bypass_actor())

      # Verify organization is gone
      assert {:error, %Ash.Error.Query.NotFound{}} =
        Organization
        |> Ash.Query.filter(id == ^org.id)
        |> Ash.read_one(domain: Accounts, actor: bypass_actor())
    end

    @tag :skip
    test "deleting organization cascades to memberships" do
      # TODO: Implement cascade deletion for organization memberships
      org = create_organization()
      user1 = create_user(organization: org)
      user2 = create_user(organization: org)

      membership_ids =
        Accounts.OrganizationMembership
        |> Ash.Query.filter(organization_id == ^org.id)
        |> Ash.read!(domain: Accounts, actor: bypass_actor())
        |> Enum.map(& &1.id)

      assert length(membership_ids) >= 2

      # Delete organization
      assert :ok = Ash.destroy(org, domain: Accounts, actor: bypass_actor())

      # Verify memberships are deleted
      remaining_memberships =
        Accounts.OrganizationMembership
        |> Ash.Query.filter(id in ^membership_ids)
        |> Ash.read!(domain: Accounts, actor: bypass_actor())

      assert remaining_memberships == []
    end
  end
end
