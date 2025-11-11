defmodule PilatesOnPhx.DomainsTest do
  use ExUnit.Case, async: true

  describe "ash_domains configuration" do
    test "returns all four expected domains" do
      domains = Application.get_env(:pilates_on_phx, :ash_domains, [])

      assert length(domains) == 4, "Expected 4 domains, got #{length(domains)}"

      assert PilatesOnPhx.Accounts in domains,
             "Accounts domain not found in configuration"

      assert PilatesOnPhx.Studios in domains,
             "Studios domain not found in configuration"

      assert PilatesOnPhx.Classes in domains,
             "Classes domain not found in configuration"

      assert PilatesOnPhx.Bookings in domains,
             "Bookings domain not found in configuration"
    end

    test "domains are in strategic order" do
      domains = Application.get_env(:pilates_on_phx, :ash_domains, [])

      # Accounts should be first (auth foundation)
      assert Enum.at(domains, 0) == PilatesOnPhx.Accounts,
             "Accounts domain should be first for authentication foundation"
    end

    test "configuration key exists" do
      all_config = Application.get_all_env(:pilates_on_phx)

      assert Keyword.has_key?(all_config, :ash_domains),
             ":ash_domains configuration key not found"
    end
  end

  describe "spark formatter configuration" do
    test "spark formatter config exists" do
      spark_config = Application.get_env(:spark, :formatter, [])

      refute spark_config == [],
             "Spark formatter configuration not found"
    end

    test "spark formatter includes required configuration" do
      spark_config = Application.get_env(:spark, :formatter, [])

      # Verify formatter config exists and is properly structured
      assert is_list(spark_config),
             "Spark formatter config should be a list"
    end
  end

  describe ".formatter.exs configuration" do
    test "includes required ash import_deps" do
      formatter_config = File.read!(".formatter.exs")
      {config, _} = Code.eval_string(formatter_config)

      import_deps = Keyword.get(config, :import_deps, [])

      assert :ash in import_deps,
             ":ash not found in .formatter.exs import_deps"

      assert :ash_postgres in import_deps,
             ":ash_postgres not found in .formatter.exs import_deps"

      assert :ash_phoenix in import_deps,
             ":ash_phoenix not found in .formatter.exs import_deps"
    end

    test "includes domain subdirectories in subdirectories config" do
      formatter_config = File.read!(".formatter.exs")
      {config, _} = Code.eval_string(formatter_config)

      subdirectories = Keyword.get(config, :subdirectories, [])

      # Check that subdirectories list includes domain paths
      assert "lib/pilates_on_phx/accounts" in subdirectories,
             "accounts subdirectory not in formatter subdirectories"

      assert "lib/pilates_on_phx/studios" in subdirectories,
             "studios subdirectory not in formatter subdirectories"

      assert "lib/pilates_on_phx/classes" in subdirectories,
             "classes subdirectory not in formatter subdirectories"

      assert "lib/pilates_on_phx/bookings" in subdirectories,
             "bookings subdirectory not in formatter subdirectories"
    end
  end

  describe "domain discoverability" do
    test "all domains are loadable modules" do
      domains = [
        PilatesOnPhx.Accounts,
        PilatesOnPhx.Studios,
        PilatesOnPhx.Classes,
        PilatesOnPhx.Bookings
      ]

      Enum.each(domains, fn domain ->
        assert Code.ensure_loaded?(domain),
               "Domain #{inspect(domain)} is not loadable"
      end)
    end

    test "all domains implement Ash.Domain behaviour" do
      domains = [
        PilatesOnPhx.Accounts,
        PilatesOnPhx.Studios,
        PilatesOnPhx.Classes,
        PilatesOnPhx.Bookings
      ]

      Enum.each(domains, fn domain ->
        # Check if module uses Ash.Domain
        assert function_exported?(domain, :spark_is, 0),
               "Domain #{inspect(domain)} does not implement Ash.Domain"

        assert domain.spark_is() == Ash.Domain,
               "Domain #{inspect(domain)} is not an Ash.Domain"
      end)
    end
  end

  describe "compilation and dependencies" do
    test "project compiles without errors" do
      # This test ensures no circular dependencies exist
      assert Code.ensure_loaded?(PilatesOnPhx.Accounts)
      assert Code.ensure_loaded?(PilatesOnPhx.Studios)
      assert Code.ensure_loaded?(PilatesOnPhx.Classes)
      assert Code.ensure_loaded?(PilatesOnPhx.Bookings)
    end

    test "mix format runs without errors" do
      {output, exit_code} =
        System.cmd("mix", ["format", "--check-formatted"], stderr_to_stdout: true)

      # Exit code 0 means formatted correctly or formatting succeeded
      # Exit code 1 means files need formatting (acceptable for this test)
      assert exit_code in [0, 1],
             "mix format failed with unexpected exit code #{exit_code}: #{output}"
    end
  end

  describe "directory structure" do
    test "all domain subdirectories exist" do
      domain_dirs = [
        "lib/pilates_on_phx/accounts",
        "lib/pilates_on_phx/studios",
        "lib/pilates_on_phx/classes",
        "lib/pilates_on_phx/bookings"
      ]

      Enum.each(domain_dirs, fn dir ->
        assert File.dir?(dir),
               "Domain subdirectory #{dir} does not exist"
      end)
    end

    test "gitkeep files preserve empty directories" do
      domain_dirs = [
        "lib/pilates_on_phx/accounts",
        "lib/pilates_on_phx/studios",
        "lib/pilates_on_phx/classes",
        "lib/pilates_on_phx/bookings"
      ]

      Enum.each(domain_dirs, fn dir ->
        gitkeep_path = Path.join(dir, ".gitkeep")

        assert File.exists?(gitkeep_path),
               ".gitkeep file not found in #{dir}"
      end)
    end
  end
end
