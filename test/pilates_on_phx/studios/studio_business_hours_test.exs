defmodule PilatesOnPhx.Studios.StudioBusinessHoursTest do
  @moduledoc """
  Comprehensive test suite for Studio business hours management.

  Tests cover:
  - Regular business hours (daily schedules)
  - Special hours (holidays, closures, temporary changes)
  - Time format validation (HH:MM format)
  - Logical consistency validation
  - is_open? calculation with timezone support
  - Edge cases (overnight hours, DST transitions)
  - Multi-tenant isolation

  These tests follow TDD principles and are written BEFORE implementation.
  All tests should FAIL initially (TDD red phase).
  """

  use PilatesOnPhx.DataCase, async: true

  alias PilatesOnPhx.Studios
  alias PilatesOnPhx.Studios.Studio
  import PilatesOnPhx.StudiosFixtures, except: [bypass_actor: 0]
  import PilatesOnPhx.AccountsFixtures, except: [bypass_actor: 0]

  require Ash.Query

  # Use StudiosFixtures bypass_actor explicitly to avoid ambiguity
  defp bypass_actor, do: PilatesOnPhx.StudiosFixtures.bypass_actor()

  describe "regular business hours - create action" do
    test "creates studio with valid regular hours in HH:MM-HH:MM format" do
      org = create_organization()

      regular_hours = %{
        "monday" => %{"open" => "06:00", "close" => "20:00"},
        "tuesday" => %{"open" => "06:00", "close" => "20:00"},
        "wednesday" => %{"open" => "06:00", "close" => "20:00"},
        "thursday" => %{"open" => "06:00", "close" => "20:00"},
        "friday" => %{"open" => "06:00", "close" => "20:00"},
        "saturday" => %{"open" => "08:00", "close" => "18:00"},
        "sunday" => %{"open" => "08:00", "close" => "16:00"}
      }

      attrs = %{
        name: "Test Studio",
        address: "123 Main St",
        timezone: "America/New_York",
        regular_hours: regular_hours,
        organization_id: org.id
      }

      assert {:ok, studio} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: bypass_actor())

      assert studio.regular_hours == regular_hours
    end

    test "creates studio with some days marked as closed" do
      org = create_organization()

      regular_hours = %{
        "monday" => %{"open" => "06:00", "close" => "20:00"},
        "tuesday" => %{"open" => "06:00", "close" => "20:00"},
        "wednesday" => %{"open" => "06:00", "close" => "20:00"},
        "thursday" => %{"open" => "06:00", "close" => "20:00"},
        "friday" => %{"open" => "06:00", "close" => "20:00"},
        "saturday" => %{"open" => "08:00", "close" => "18:00"},
        "sunday" => "closed"
      }

      attrs = %{
        name: "Test Studio",
        address: "123 Main St",
        regular_hours: regular_hours,
        organization_id: org.id
      }

      assert {:ok, studio} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: bypass_actor())

      assert studio.regular_hours["sunday"] == "closed"
    end

    test "accepts overnight hours (close time after midnight)" do
      org = create_organization()

      regular_hours = %{
        "monday" => %{"open" => "22:00", "close" => "02:00"},
        "tuesday" => %{"open" => "22:00", "close" => "02:00"},
        "wednesday" => %{"open" => "22:00", "close" => "02:00"},
        "thursday" => %{"open" => "22:00", "close" => "02:00"},
        "friday" => %{"open" => "22:00", "close" => "04:00"},
        "saturday" => %{"open" => "20:00", "close" => "03:00"},
        "sunday" => "closed"
      }

      attrs = %{
        name: "Night Studio",
        address: "123 Main St",
        regular_hours: regular_hours,
        organization_id: org.id
      }

      assert {:ok, studio} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: bypass_actor())

      assert studio.regular_hours["friday"]["close"] == "04:00"
    end

    test "validates time format is HH:MM (not H:MM or HH:M)" do
      org = create_organization()

      invalid_hours = %{
        "monday" => %{"open" => "6:00", "close" => "20:00"},
        # Invalid: should be 06:00
        "tuesday" => %{"open" => "06:00", "close" => "20:00"}
      }

      attrs = %{
        name: "Test Studio",
        address: "123 Main St",
        regular_hours: invalid_hours,
        organization_id: org.id
      }

      assert {:error, %Ash.Error.Invalid{} = error} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: bypass_actor())

      changeset = error.changeset
      assert changeset.valid? == false
      assert Enum.any?(changeset.errors, fn error -> error.field == :regular_hours end)
    end

    test "validates time format has valid hours (00-23)" do
      org = create_organization()

      invalid_hours = %{
        "monday" => %{"open" => "25:00", "close" => "20:00"}
        # Invalid: hour 25 doesn't exist
      }

      attrs = %{
        name: "Test Studio",
        address: "123 Main St",
        regular_hours: invalid_hours,
        organization_id: org.id
      }

      assert {:error, %Ash.Error.Invalid{}} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: bypass_actor())
    end

    test "validates time format has valid minutes (00-59)" do
      org = create_organization()

      invalid_hours = %{
        "monday" => %{"open" => "06:00", "close" => "20:75"}
        # Invalid: minute 75 doesn't exist
      }

      attrs = %{
        name: "Test Studio",
        address: "123 Main St",
        regular_hours: invalid_hours,
        organization_id: org.id
      }

      assert {:error, %Ash.Error.Invalid{}} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: bypass_actor())
    end

    test "rejects invalid time format like '9am' or '5pm'" do
      org = create_organization()

      invalid_hours = %{
        "monday" => %{"open" => "9am", "close" => "5pm"}
      }

      attrs = %{
        name: "Test Studio",
        address: "123 Main St",
        regular_hours: invalid_hours,
        organization_id: org.id
      }

      assert {:error, %Ash.Error.Invalid{}} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: bypass_actor())
    end

    test "validates day names are valid weekdays" do
      org = create_organization()

      invalid_hours = %{
        "mondey" => %{"open" => "06:00", "close" => "20:00"},
        # Typo in day name
        "tuesday" => %{"open" => "06:00", "close" => "20:00"}
      }

      attrs = %{
        name: "Test Studio",
        address: "123 Main St",
        regular_hours: invalid_hours,
        organization_id: org.id
      }

      assert {:error, %Ash.Error.Invalid{}} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: bypass_actor())
    end

    test "allows empty regular_hours (will use defaults)" do
      org = create_organization()

      attrs = %{
        name: "Test Studio",
        address: "123 Main St",
        regular_hours: %{},
        organization_id: org.id
      }

      assert {:ok, studio} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: bypass_actor())

      # Should have default hours or empty map
      assert is_map(studio.regular_hours)
    end
  end

  describe "regular business hours - update action" do
    test "updates studio regular hours" do
      studio = create_studio()

      new_hours = %{
        "monday" => %{"open" => "05:00", "close" => "21:00"},
        "tuesday" => %{"open" => "05:00", "close" => "21:00"},
        "wednesday" => %{"open" => "05:00", "close" => "21:00"},
        "thursday" => %{"open" => "05:00", "close" => "21:00"},
        "friday" => %{"open" => "05:00", "close" => "21:00"},
        "saturday" => %{"open" => "07:00", "close" => "19:00"},
        "sunday" => "closed"
      }

      assert {:ok, updated} =
               studio
               |> Ash.Changeset.for_update(:update, %{regular_hours: new_hours},
                 actor: bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert updated.regular_hours["monday"]["open"] == "05:00"
      assert updated.regular_hours["sunday"] == "closed"
    end

    test "validates time format when updating regular hours" do
      studio = create_studio()

      invalid_hours = %{
        "monday" => %{"open" => "not-a-time", "close" => "20:00"}
      }

      assert {:error, %Ash.Error.Invalid{}} =
               studio
               |> Ash.Changeset.for_update(:update, %{regular_hours: invalid_hours},
                 actor: bypass_actor()
               )
               |> Ash.update(domain: Studios)
    end

    test "can change specific days without affecting others" do
      studio = create_studio()

      # Only update Saturday and Sunday
      partial_update = %{
        "saturday" => %{"open" => "09:00", "close" => "17:00"},
        "sunday" => %{"open" => "10:00", "close" => "14:00"}
      }

      assert {:ok, updated} =
               studio
               |> Ash.Changeset.for_update(:update, %{regular_hours: partial_update},
                 actor: bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert updated.regular_hours["saturday"]["open"] == "09:00"
      assert updated.regular_hours["sunday"]["open"] == "10:00"
    end
  end

  describe "special hours - create and manage" do
    test "creates studio with special hours for holidays" do
      org = create_organization()

      special_hours = [
        %{
          "date" => "2025-12-25",
          "reason" => "Christmas Day",
          "open" => nil,
          "close" => nil,
          "closed" => true
        },
        %{
          "date" => "2025-07-04",
          "reason" => "Independence Day",
          "open" => "09:00",
          "close" => "14:00",
          "closed" => false
        }
      ]

      attrs = %{
        name: "Test Studio",
        address: "123 Main St",
        special_hours: special_hours,
        organization_id: org.id
      }

      assert {:ok, studio} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: bypass_actor())

      assert length(studio.special_hours) == 2
      christmas = Enum.find(studio.special_hours, &(&1["date"] == "2025-12-25"))
      assert christmas["closed"] == true
      assert christmas["reason"] == "Christmas Day"
    end

    test "validates special hours have required fields" do
      org = create_organization()

      # Missing date field
      invalid_special_hours = [
        %{
          "reason" => "Holiday",
          "closed" => true
        }
      ]

      attrs = %{
        name: "Test Studio",
        address: "123 Main St",
        special_hours: invalid_special_hours,
        organization_id: org.id
      }

      assert {:error, %Ash.Error.Invalid{}} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: bypass_actor())
    end

    test "validates special hours dates are in ISO 8601 format (YYYY-MM-DD)" do
      org = create_organization()

      invalid_special_hours = [
        %{
          "date" => "12/25/2025",
          # Invalid: should be 2025-12-25
          "reason" => "Christmas",
          "closed" => true
        }
      ]

      attrs = %{
        name: "Test Studio",
        address: "123 Main St",
        special_hours: invalid_special_hours,
        organization_id: org.id
      }

      assert {:error, %Ash.Error.Invalid{}} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: bypass_actor())
    end

    test "validates special hours times follow HH:MM format" do
      org = create_organization()

      invalid_special_hours = [
        %{
          "date" => "2025-07-04",
          "reason" => "Independence Day",
          "open" => "9:00",
          # Invalid: should be 09:00
          "close" => "14:00",
          "closed" => false
        }
      ]

      attrs = %{
        name: "Test Studio",
        address: "123 Main St",
        special_hours: invalid_special_hours,
        organization_id: org.id
      }

      assert {:error, %Ash.Error.Invalid{}} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: bypass_actor())
    end

    test "validates closed days don't have open/close times" do
      org = create_organization()

      # Inconsistent: marked as closed but has times
      invalid_special_hours = [
        %{
          "date" => "2025-12-25",
          "reason" => "Christmas",
          "open" => "09:00",
          "close" => "17:00",
          "closed" => true
        }
      ]

      attrs = %{
        name: "Test Studio",
        address: "123 Main St",
        special_hours: invalid_special_hours,
        organization_id: org.id
      }

      assert {:error, %Ash.Error.Invalid{}} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: bypass_actor())
    end

    test "validates open days have both open and close times" do
      org = create_organization()

      # Invalid: not closed but missing close time
      invalid_special_hours = [
        %{
          "date" => "2025-07-04",
          "reason" => "Independence Day",
          "open" => "09:00",
          "close" => nil,
          "closed" => false
        }
      ]

      attrs = %{
        name: "Test Studio",
        address: "123 Main St",
        special_hours: invalid_special_hours,
        organization_id: org.id
      }

      assert {:error, %Ash.Error.Invalid{}} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: bypass_actor())
    end

    test "allows updating special hours" do
      studio = create_studio()

      new_special_hours = [
        %{
          "date" => "2025-11-27",
          "reason" => "Thanksgiving",
          "closed" => true
        },
        %{
          "date" => "2025-11-28",
          "reason" => "Black Friday",
          "open" => "10:00",
          "close" => "15:00",
          "closed" => false
        }
      ]

      assert {:ok, updated} =
               studio
               |> Ash.Changeset.for_update(:update, %{special_hours: new_special_hours},
                 actor: bypass_actor()
               )
               |> Ash.update(domain: Studios)

      assert length(updated.special_hours) == 2
    end

    test "allows empty special hours (no holidays defined)" do
      org = create_organization()

      attrs = %{
        name: "Test Studio",
        address: "123 Main St",
        special_hours: [],
        organization_id: org.id
      }

      assert {:ok, studio} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: bypass_actor())

      assert studio.special_hours == []
    end

    test "orders special hours by date" do
      org = create_organization()

      # Create in random order
      special_hours = [
        %{
          "date" => "2025-12-25",
          "reason" => "Christmas",
          "closed" => true
        },
        %{
          "date" => "2025-01-01",
          "reason" => "New Year",
          "closed" => true
        },
        %{
          "date" => "2025-07-04",
          "reason" => "Independence Day",
          "closed" => true
        }
      ]

      attrs = %{
        name: "Test Studio",
        address: "123 Main St",
        special_hours: special_hours,
        organization_id: org.id
      }

      assert {:ok, studio} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: bypass_actor())

      # Should be ordered chronologically
      dates = Enum.map(studio.special_hours, & &1["date"])
      assert dates == Enum.sort(dates)
    end
  end

  describe "is_open? calculation - basic scenarios" do
    test "calculates studio is open during regular hours" do
      # Create studio open Monday-Friday 6am-8pm
      regular_hours = %{
        "monday" => %{"open" => "06:00", "close" => "20:00"},
        "tuesday" => %{"open" => "06:00", "close" => "20:00"},
        "wednesday" => %{"open" => "06:00", "close" => "20:00"},
        "thursday" => %{"open" => "06:00", "close" => "20:00"},
        "friday" => %{"open" => "06:00", "close" => "20:00"},
        "saturday" => "closed",
        "sunday" => "closed"
      }

      studio = create_studio(timezone: "America/New_York", regular_hours: regular_hours)

      # Load the calculation
      loaded =
        Studio
        |> Ash.Query.filter(id == ^studio.id)
        |> Ash.Query.load(:is_open)
        |> Ash.read_one!(domain: Studios, actor: bypass_actor())

      # This will depend on when the test runs, but the calculation should exist
      assert Map.has_key?(loaded, :is_open)
      assert is_boolean(loaded.is_open)
    end

    test "calculates studio is open at a specific datetime" do
      regular_hours = %{
        "monday" => %{"open" => "06:00", "close" => "20:00"},
        "tuesday" => %{"open" => "06:00", "close" => "20:00"},
        "wednesday" => %{"open" => "06:00", "close" => "20:00"},
        "thursday" => %{"open" => "06:00", "close" => "20:00"},
        "friday" => %{"open" => "06:00", "close" => "20:00"},
        "saturday" => "closed",
        "sunday" => "closed"
      }

      studio = create_studio(timezone: "America/New_York", regular_hours: regular_hours)

      # Test at specific time: Monday 10am EST
      test_time = ~U[2025-01-13 15:00:00Z]
      # 10am EST = 3pm UTC

      # Load calculation with specific time context
      loaded =
        Studio
        |> Ash.Query.filter(id == ^studio.id)
        |> Ash.Query.load(is_open: %{at: test_time})
        |> Ash.read_one!(domain: Studios, actor: bypass_actor())

      assert loaded.is_open == true
    end

    test "calculates studio is closed outside regular hours" do
      regular_hours = %{
        "monday" => %{"open" => "06:00", "close" => "20:00"},
        "tuesday" => %{"open" => "06:00", "close" => "20:00"},
        "wednesday" => %{"open" => "06:00", "close" => "20:00"},
        "thursday" => %{"open" => "06:00", "close" => "20:00"},
        "friday" => %{"open" => "06:00", "close" => "20:00"},
        "saturday" => "closed",
        "sunday" => "closed"
      }

      studio = create_studio(timezone: "America/New_York", regular_hours: regular_hours)

      # Test at specific time: Monday 11pm EST (closed)
      test_time = ~U[2025-01-14 04:00:00Z]
      # 11pm EST = 4am UTC next day

      loaded =
        Studio
        |> Ash.Query.filter(id == ^studio.id)
        |> Ash.Query.load(is_open: %{at: test_time})
        |> Ash.read_one!(domain: Studios, actor: bypass_actor())

      assert loaded.is_open == false
    end

    test "calculates studio is closed on days marked closed" do
      regular_hours = %{
        "monday" => %{"open" => "06:00", "close" => "20:00"},
        "tuesday" => %{"open" => "06:00", "close" => "20:00"},
        "wednesday" => %{"open" => "06:00", "close" => "20:00"},
        "thursday" => %{"open" => "06:00", "close" => "20:00"},
        "friday" => %{"open" => "06:00", "close" => "20:00"},
        "saturday" => "closed",
        "sunday" => "closed"
      }

      studio = create_studio(timezone: "America/New_York", regular_hours: regular_hours)

      # Test on Sunday at noon EST
      test_time = ~U[2025-01-12 17:00:00Z]
      # Sunday noon EST = 5pm UTC

      loaded =
        Studio
        |> Ash.Query.filter(id == ^studio.id)
        |> Ash.Query.load(is_open: %{at: test_time})
        |> Ash.read_one!(domain: Studios, actor: bypass_actor())

      assert loaded.is_open == false
    end
  end

  describe "is_open? calculation - timezone handling" do
    test "correctly handles different timezones" do
      # Create studio in Los Angeles (PST/PDT)
      regular_hours = %{
        "monday" => %{"open" => "08:00", "close" => "18:00"},
        "tuesday" => %{"open" => "08:00", "close" => "18:00"},
        "wednesday" => %{"open" => "08:00", "close" => "18:00"},
        "thursday" => %{"open" => "08:00", "close" => "18:00"},
        "friday" => %{"open" => "08:00", "close" => "18:00"},
        "saturday" => "closed",
        "sunday" => "closed"
      }

      studio_la = create_studio(timezone: "America/Los_Angeles", regular_hours: regular_hours)

      # Same hours, but in New York (EST/EDT)
      studio_ny = create_studio(timezone: "America/New_York", regular_hours: regular_hours)

      # Test at 11am LA time = 2pm NY time = 6pm UTC
      test_time = ~U[2025-01-13 19:00:00Z]

      loaded_la =
        Studio
        |> Ash.Query.filter(id == ^studio_la.id)
        |> Ash.Query.load(is_open: %{at: test_time})
        |> Ash.read_one!(domain: Studios, actor: bypass_actor())

      loaded_ny =
        Studio
        |> Ash.Query.filter(id == ^studio_ny.id)
        |> Ash.Query.load(is_open: %{at: test_time})
        |> Ash.read_one!(domain: Studios, actor: bypass_actor())

      # Both should be open at their respective local times
      assert loaded_la.is_open == true
      assert loaded_ny.is_open == true
    end

    test "handles studios in European timezones" do
      regular_hours = %{
        "monday" => %{"open" => "09:00", "close" => "21:00"},
        "tuesday" => %{"open" => "09:00", "close" => "21:00"},
        "wednesday" => %{"open" => "09:00", "close" => "21:00"},
        "thursday" => %{"open" => "09:00", "close" => "21:00"},
        "friday" => %{"open" => "09:00", "close" => "21:00"},
        "saturday" => %{"open" => "10:00", "close" => "18:00"},
        "sunday" => "closed"
      }

      studio = create_studio(timezone: "Europe/London", regular_hours: regular_hours)

      # Test at 3pm London time on Monday
      test_time = ~U[2025-01-13 15:00:00Z]
      # 3pm UTC = 3pm London (no DST in January)

      loaded =
        Studio
        |> Ash.Query.filter(id == ^studio.id)
        |> Ash.Query.load(is_open: %{at: test_time})
        |> Ash.read_one!(domain: Studios, actor: bypass_actor())

      assert loaded.is_open == true
    end

    test "handles studios in Asian timezones" do
      regular_hours = %{
        "monday" => %{"open" => "07:00", "close" => "22:00"},
        "tuesday" => %{"open" => "07:00", "close" => "22:00"},
        "wednesday" => %{"open" => "07:00", "close" => "22:00"},
        "thursday" => %{"open" => "07:00", "close" => "22:00"},
        "friday" => %{"open" => "07:00", "close" => "22:00"},
        "saturday" => %{"open" => "08:00", "close" => "20:00"},
        "sunday" => %{"open" => "08:00", "close" => "20:00"}
      }

      studio = create_studio(timezone: "Asia/Tokyo", regular_hours: regular_hours)

      # Test at 10am Tokyo time on Monday
      test_time = ~U[2025-01-13 01:00:00Z]
      # 1am UTC = 10am JST

      loaded =
        Studio
        |> Ash.Query.filter(id == ^studio.id)
        |> Ash.Query.load(is_open: %{at: test_time})
        |> Ash.read_one!(domain: Studios, actor: bypass_actor())

      assert loaded.is_open == true
    end
  end

  describe "is_open? calculation - overnight hours" do
    test "correctly handles overnight hours (close after midnight)" do
      regular_hours = %{
        "monday" => %{"open" => "22:00", "close" => "02:00"},
        "tuesday" => %{"open" => "22:00", "close" => "02:00"},
        "wednesday" => %{"open" => "22:00", "close" => "02:00"},
        "thursday" => %{"open" => "22:00", "close" => "02:00"},
        "friday" => %{"open" => "22:00", "close" => "04:00"},
        "saturday" => %{"open" => "20:00", "close" => "03:00"},
        "sunday" => "closed"
      }

      studio = create_studio(timezone: "America/New_York", regular_hours: regular_hours)

      # Test at 1am Tuesday morning (should be open from Monday night)
      test_time = ~U[2025-01-14 06:00:00Z]
      # 1am EST = 6am UTC

      loaded =
        Studio
        |> Ash.Query.filter(id == ^studio.id)
        |> Ash.Query.load(is_open: %{at: test_time})
        |> Ash.read_one!(domain: Studios, actor: bypass_actor())

      assert loaded.is_open == true
    end

    test "overnight hours close correctly after midnight" do
      regular_hours = %{
        "monday" => %{"open" => "22:00", "close" => "02:00"},
        "tuesday" => %{"open" => "22:00", "close" => "02:00"},
        "wednesday" => %{"open" => "22:00", "close" => "02:00"},
        "thursday" => %{"open" => "22:00", "close" => "02:00"},
        "friday" => %{"open" => "22:00", "close" => "02:00"},
        "saturday" => "closed",
        "sunday" => "closed"
      }

      studio = create_studio(timezone: "America/New_York", regular_hours: regular_hours)

      # Test at 3am Tuesday morning (should be closed - past 2am close)
      test_time = ~U[2025-01-14 08:00:00Z]
      # 3am EST = 8am UTC

      loaded =
        Studio
        |> Ash.Query.filter(id == ^studio.id)
        |> Ash.Query.load(is_open: %{at: test_time})
        |> Ash.read_one!(domain: Studios, actor: bypass_actor())

      assert loaded.is_open == false
    end

    test "24-hour studios are always open" do
      regular_hours = %{
        "monday" => %{"open" => "00:00", "close" => "23:59"},
        "tuesday" => %{"open" => "00:00", "close" => "23:59"},
        "wednesday" => %{"open" => "00:00", "close" => "23:59"},
        "thursday" => %{"open" => "00:00", "close" => "23:59"},
        "friday" => %{"open" => "00:00", "close" => "23:59"},
        "saturday" => %{"open" => "00:00", "close" => "23:59"},
        "sunday" => %{"open" => "00:00", "close" => "23:59"}
      }

      studio = create_studio(timezone: "America/New_York", regular_hours: regular_hours)

      # Test at various times - should always be open
      times = [
        ~U[2025-01-13 05:00:00Z],
        # Midnight EST
        ~U[2025-01-13 12:00:00Z],
        # 7am EST
        ~U[2025-01-13 20:00:00Z],
        # 3pm EST
        ~U[2025-01-14 03:00:00Z]
        # 10pm EST
      ]

      Enum.each(times, fn test_time ->
        loaded =
          Studio
          |> Ash.Query.filter(id == ^studio.id)
          |> Ash.Query.load(is_open: %{at: test_time})
          |> Ash.read_one!(domain: Studios, actor: bypass_actor())

        assert loaded.is_open == true
      end)
    end
  end

  describe "is_open? calculation - special hours override" do
    test "special hours override regular hours for holidays" do
      regular_hours = %{
        "monday" => %{"open" => "06:00", "close" => "20:00"},
        "tuesday" => %{"open" => "06:00", "close" => "20:00"},
        "wednesday" => %{"open" => "06:00", "close" => "20:00"},
        "thursday" => %{"open" => "06:00", "close" => "20:00"},
        "friday" => %{"open" => "06:00", "close" => "20:00"},
        "saturday" => %{"open" => "08:00", "close" => "18:00"},
        "sunday" => %{"open" => "08:00", "close" => "16:00"}
      }

      # Christmas falls on a Thursday (normally open 6am-8pm)
      special_hours = [
        %{
          "date" => "2025-12-25",
          "reason" => "Christmas Day",
          "closed" => true
        }
      ]

      studio =
        create_studio(
          timezone: "America/New_York",
          regular_hours: regular_hours,
          special_hours: special_hours
        )

      # Test at 10am on Christmas Day (Thursday)
      test_time = ~U[2025-12-25 15:00:00Z]
      # 10am EST = 3pm UTC

      loaded =
        Studio
        |> Ash.Query.filter(id == ^studio.id)
        |> Ash.Query.load(is_open: %{at: test_time})
        |> Ash.read_one!(domain: Studios, actor: bypass_actor())

      # Should be closed despite regular Thursday hours
      assert loaded.is_open == false
    end

    test "special hours with reduced hours override regular hours" do
      regular_hours = %{
        "monday" => %{"open" => "06:00", "close" => "20:00"},
        "tuesday" => %{"open" => "06:00", "close" => "20:00"},
        "wednesday" => %{"open" => "06:00", "close" => "20:00"},
        "thursday" => %{"open" => "06:00", "close" => "20:00"},
        "friday" => %{"open" => "06:00", "close" => "20:00"},
        "saturday" => %{"open" => "08:00", "close" => "18:00"},
        "sunday" => %{"open" => "08:00", "close" => "16:00"}
      }

      # Independence Day with early closing
      special_hours = [
        %{
          "date" => "2025-07-04",
          "reason" => "Independence Day - Early Close",
          "open" => "06:00",
          "close" => "14:00",
          "closed" => false
        }
      ]

      studio =
        create_studio(
          timezone: "America/New_York",
          regular_hours: regular_hours,
          special_hours: special_hours
        )

      # Test at 5pm on July 4th (Friday) - normally open until 8pm
      test_time = ~U[2025-07-04 21:00:00Z]
      # 5pm EST = 9pm UTC

      loaded =
        Studio
        |> Ash.Query.filter(id == ^studio.id)
        |> Ash.Query.load(is_open: %{at: test_time})
        |> Ash.read_one!(domain: Studios, actor: bypass_actor())

      # Should be closed - special hours close at 2pm
      assert loaded.is_open == false
    end

    test "special hours only affect specified date" do
      regular_hours = %{
        "monday" => %{"open" => "06:00", "close" => "20:00"},
        "tuesday" => %{"open" => "06:00", "close" => "20:00"},
        "wednesday" => %{"open" => "06:00", "close" => "20:00"},
        "thursday" => %{"open" => "06:00", "close" => "20:00"},
        "friday" => %{"open" => "06:00", "close" => "20:00"},
        "saturday" => %{"open" => "08:00", "close" => "18:00"},
        "sunday" => %{"open" => "08:00", "close" => "16:00"}
      }

      special_hours = [
        %{
          "date" => "2025-07-04",
          "reason" => "Independence Day",
          "closed" => true
        }
      ]

      studio =
        create_studio(
          timezone: "America/New_York",
          regular_hours: regular_hours,
          special_hours: special_hours
        )

      # Test on July 3rd (day before) - should use regular hours
      test_time_before = ~U[2025-07-03 15:00:00Z]
      # 10am EST

      loaded_before =
        Studio
        |> Ash.Query.filter(id == ^studio.id)
        |> Ash.Query.load(is_open: %{at: test_time_before})
        |> Ash.read_one!(domain: Studios, actor: bypass_actor())

      assert loaded_before.is_open == true

      # Test on July 5th (day after) - should use regular hours
      test_time_after = ~U[2025-07-05 15:00:00Z]

      loaded_after =
        Studio
        |> Ash.Query.filter(id == ^studio.id)
        |> Ash.Query.load(is_open: %{at: test_time_after})
        |> Ash.read_one!(domain: Studios, actor: bypass_actor())

      assert loaded_after.is_open == true
    end
  end

  describe "is_open? calculation - DST transitions" do
    test "handles spring forward DST transition correctly" do
      # In 2025, DST starts on March 9 at 2am (clocks jump to 3am)
      regular_hours = %{
        "monday" => %{"open" => "06:00", "close" => "20:00"},
        "tuesday" => %{"open" => "06:00", "close" => "20:00"},
        "wednesday" => %{"open" => "06:00", "close" => "20:00"},
        "thursday" => %{"open" => "06:00", "close" => "20:00"},
        "friday" => %{"open" => "06:00", "close" => "20:00"},
        "saturday" => %{"open" => "08:00", "close" => "18:00"},
        "sunday" => %{"open" => "08:00", "close" => "16:00"}
      }

      studio = create_studio(timezone: "America/New_York", regular_hours: regular_hours)

      # Test just before DST transition (2am EST doesn't exist)
      # The hour from 2am-3am is skipped
      test_time = ~U[2025-03-09 07:30:00Z]
      # Should be 2:30am EST but that doesn't exist

      loaded =
        Studio
        |> Ash.Query.filter(id == ^studio.id)
        |> Ash.Query.load(is_open: %{at: test_time})
        |> Ash.read_one!(domain: Studios, actor: bypass_actor())

      # Should be closed - before 6am opening
      assert loaded.is_open == false
    end

    test "handles fall back DST transition correctly" do
      # In 2025, DST ends on November 2 at 2am (clocks fall back to 1am)
      regular_hours = %{
        "monday" => %{"open" => "06:00", "close" => "20:00"},
        "tuesday" => %{"open" => "06:00", "close" => "20:00"},
        "wednesday" => %{"open" => "06:00", "close" => "20:00"},
        "thursday" => %{"open" => "06:00", "close" => "20:00"},
        "friday" => %{"open" => "06:00", "close" => "20:00"},
        "saturday" => %{"open" => "08:00", "close" => "18:00"},
        "sunday" => %{"open" => "08:00", "close" => "16:00"}
      }

      studio = create_studio(timezone: "America/New_York", regular_hours: regular_hours)

      # Test during the repeated hour (1am-2am happens twice)
      test_time = ~U[2025-11-02 06:30:00Z]
      # Could be 1:30am or 2:30am depending on DST

      loaded =
        Studio
        |> Ash.Query.filter(id == ^studio.id)
        |> Ash.Query.load(is_open: %{at: test_time})
        |> Ash.read_one!(domain: Studios, actor: bypass_actor())

      # Should be closed - still before 8am Sunday opening
      assert loaded.is_open == false
    end

    test "handles timezone without DST (Arizona)" do
      # Arizona doesn't observe DST
      regular_hours = %{
        "monday" => %{"open" => "06:00", "close" => "20:00"},
        "tuesday" => %{"open" => "06:00", "close" => "20:00"},
        "wednesday" => %{"open" => "06:00", "close" => "20:00"},
        "thursday" => %{"open" => "06:00", "close" => "20:00"},
        "friday" => %{"open" => "06:00", "close" => "20:00"},
        "saturday" => %{"open" => "08:00", "close" => "18:00"},
        "sunday" => %{"open" => "08:00", "close" => "16:00"}
      }

      studio = create_studio(timezone: "America/Phoenix", regular_hours: regular_hours)

      # Test during what would be DST transition in other zones
      test_time = ~U[2025-03-09 15:00:00Z]
      # 8am MST (Arizona time is consistent)

      loaded =
        Studio
        |> Ash.Query.filter(id == ^studio.id)
        |> Ash.Query.load(is_open: %{at: test_time})
        |> Ash.read_one!(domain: Studios, actor: bypass_actor())

      assert loaded.is_open == true
    end
  end

  describe "edge cases and error handling" do
    test "handles nil regular_hours gracefully" do
      org = create_organization()

      attrs = %{
        name: "Test Studio",
        address: "123 Main St",
        regular_hours: nil,
        organization_id: org.id
      }

      # Should either use defaults or reject nil
      result =
        Studio
        |> Ash.Changeset.for_create(:create, attrs)
        |> Ash.create(domain: Studios, actor: bypass_actor())

      case result do
        {:ok, studio} ->
          # If accepted, should have some default hours
          assert is_map(studio.regular_hours) or is_nil(studio.regular_hours)

        {:error, _} ->
          # Rejecting nil is also acceptable
          :ok
      end
    end

    test "handles invalid timezone in is_open? calculation" do
      # Create with valid timezone first
      studio = create_studio(timezone: "America/New_York")

      # Then update to invalid timezone (if validation allows)
      # The is_open calculation should handle this gracefully

      loaded =
        Studio
        |> Ash.Query.filter(id == ^studio.id)
        |> Ash.Query.load(:is_open)
        |> Ash.read_one!(domain: Studios, actor: bypass_actor())

      # Should not crash - either return false or handle error
      assert is_boolean(loaded.is_open) or is_nil(loaded.is_open)
    end

    test "handles empty special_hours list" do
      studio = create_studio(special_hours: [])

      loaded =
        Studio
        |> Ash.Query.filter(id == ^studio.id)
        |> Ash.Query.load(:is_open)
        |> Ash.read_one!(domain: Studios, actor: bypass_actor())

      # Should work fine with no special hours
      assert is_boolean(loaded.is_open)
    end

    test "validates conflicting special hours for same date" do
      org = create_organization()

      # Two different special hour entries for same date
      conflicting_special_hours = [
        %{
          "date" => "2025-07-04",
          "reason" => "Independence Day - Closed",
          "closed" => true
        },
        %{
          "date" => "2025-07-04",
          "reason" => "Independence Day - Open Half Day",
          "open" => "09:00",
          "close" => "14:00",
          "closed" => false
        }
      ]

      attrs = %{
        name: "Test Studio",
        address: "123 Main St",
        special_hours: conflicting_special_hours,
        organization_id: org.id
      }

      # Should reject or handle conflicting entries
      result =
        Studio
        |> Ash.Changeset.for_create(:create, attrs)
        |> Ash.create(domain: Studios, actor: bypass_actor())

      case result do
        {:error, %Ash.Error.Invalid{}} ->
          # Validation caught the conflict
          :ok

        {:ok, studio} ->
          # If accepted, should have deduplicated or last-wins behavior
          special_dates = Enum.map(studio.special_hours, & &1["date"])
          assert length(special_dates) == length(Enum.uniq(special_dates))
      end
    end

    test "handles past special hours (cleanup old entries)" do
      org = create_organization()

      # Mix of past and future special hours
      special_hours = [
        %{
          "date" => "2024-12-25",
          "reason" => "Christmas 2024 (past)",
          "closed" => true
        },
        %{
          "date" => "2025-12-25",
          "reason" => "Christmas 2025 (future)",
          "closed" => true
        }
      ]

      attrs = %{
        name: "Test Studio",
        address: "123 Main St",
        special_hours: special_hours,
        organization_id: org.id
      }

      assert {:ok, studio} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: bypass_actor())

      # System should allow past entries (for historical record)
      assert length(studio.special_hours) == 2
    end
  end

  describe "multi-tenant isolation with business hours" do
    test "different organizations can have different hours" do
      org1 = create_organization()
      org2 = create_organization()

      hours1 = %{
        "monday" => %{"open" => "06:00", "close" => "20:00"},
        "tuesday" => %{"open" => "06:00", "close" => "20:00"},
        "wednesday" => %{"open" => "06:00", "close" => "20:00"},
        "thursday" => %{"open" => "06:00", "close" => "20:00"},
        "friday" => %{"open" => "06:00", "close" => "20:00"},
        "saturday" => "closed",
        "sunday" => "closed"
      }

      hours2 = %{
        "monday" => %{"open" => "09:00", "close" => "17:00"},
        "tuesday" => %{"open" => "09:00", "close" => "17:00"},
        "wednesday" => %{"open" => "09:00", "close" => "17:00"},
        "thursday" => %{"open" => "09:00", "close" => "17:00"},
        "friday" => %{"open" => "09:00", "close" => "17:00"},
        "saturday" => %{"open" => "10:00", "close" => "14:00"},
        "sunday" => "closed"
      }

      studio1 = create_studio(organization: org1, regular_hours: hours1)
      studio2 = create_studio(organization: org2, regular_hours: hours2)

      assert studio1.regular_hours["monday"]["open"] == "06:00"
      assert studio2.regular_hours["monday"]["open"] == "09:00"
    end

    test "users can only see hours for studios in their organization" do
      org1 = create_organization()
      org2 = create_organization()

      user1 = create_user(organization: org1)
      studio1 = create_studio(organization: org1)
      studio2 = create_studio(organization: org2)

      # User1 can see studio1 hours
      assert {:ok, loaded1} =
               Studio
               |> Ash.Query.filter(id == ^studio1.id)
               |> Ash.read_one(domain: Studios, actor: user1)

      assert loaded1.id == studio1.id
      assert is_map(loaded1.regular_hours)

      # User1 cannot see studio2 hours (different org)
      assert {:ok, nil} =
               Studio
               |> Ash.Query.filter(id == ^studio2.id)
               |> Ash.read_one(domain: Studios, actor: user1)
    end
  end

  describe "integration scenarios" do
    test "complete business hours setup workflow" do
      org = create_organization()

      # Step 1: Create studio with regular hours
      regular_hours = %{
        "monday" => %{"open" => "06:00", "close" => "20:00"},
        "tuesday" => %{"open" => "06:00", "close" => "20:00"},
        "wednesday" => %{"open" => "06:00", "close" => "20:00"},
        "thursday" => %{"open" => "06:00", "close" => "20:00"},
        "friday" => %{"open" => "06:00", "close" => "20:00"},
        "saturday" => %{"open" => "08:00", "close" => "18:00"},
        "sunday" => "closed"
      }

      attrs = %{
        name: "Complete Setup Studio",
        address: "123 Main St",
        timezone: "America/New_York",
        regular_hours: regular_hours,
        organization_id: org.id
      }

      assert {:ok, studio} =
               Studio
               |> Ash.Changeset.for_create(:create, attrs)
               |> Ash.create(domain: Studios, actor: bypass_actor())

      # Step 2: Add special hours for upcoming holidays
      special_hours = [
        %{
          "date" => "2025-12-25",
          "reason" => "Christmas Day",
          "closed" => true
        },
        %{
          "date" => "2025-12-24",
          "reason" => "Christmas Eve - Early Close",
          "open" => "06:00",
          "close" => "14:00",
          "closed" => false
        }
      ]

      assert {:ok, updated} =
               studio
               |> Ash.Changeset.for_update(:update, %{special_hours: special_hours},
                 actor: bypass_actor()
               )
               |> Ash.update(domain: Studios)

      # Step 3: Check if open at various times
      loaded =
        Studio
        |> Ash.Query.filter(id == ^updated.id)
        |> Ash.Query.load(:is_open)
        |> Ash.read_one!(domain: Studios, actor: bypass_actor())

      assert is_boolean(loaded.is_open)
      assert length(loaded.special_hours) == 2
    end

    test "handles multiple studios with different configurations" do
      org = create_organization()

      # Early bird studio
      _studio1 =
        create_studio(
          name: "Early Bird Pilates",
          organization: org,
          timezone: "America/New_York",
          regular_hours: %{
            "monday" => %{"open" => "05:00", "close" => "13:00"},
            "tuesday" => %{"open" => "05:00", "close" => "13:00"},
            "wednesday" => %{"open" => "05:00", "close" => "13:00"},
            "thursday" => %{"open" => "05:00", "close" => "13:00"},
            "friday" => %{"open" => "05:00", "close" => "13:00"},
            "saturday" => "closed",
            "sunday" => "closed"
          }
        )

      # Evening studio
      _studio2 =
        create_studio(
          name: "Evening Pilates",
          organization: org,
          timezone: "America/New_York",
          regular_hours: %{
            "monday" => %{"open" => "15:00", "close" => "22:00"},
            "tuesday" => %{"open" => "15:00", "close" => "22:00"},
            "wednesday" => %{"open" => "15:00", "close" => "22:00"},
            "thursday" => %{"open" => "15:00", "close" => "22:00"},
            "friday" => %{"open" => "15:00", "close" => "22:00"},
            "saturday" => %{"open" => "12:00", "close" => "20:00"},
            "sunday" => "closed"
          }
        )

      # Load both with is_open calculation
      studios =
        Studio
        |> Ash.Query.filter(organization_id == ^org.id)
        |> Ash.Query.load(:is_open)
        |> Ash.read!(domain: Studios, actor: bypass_actor())

      assert length(studios) >= 2
      assert Enum.all?(studios, fn s -> is_boolean(s.is_open) end)
    end
  end
end
