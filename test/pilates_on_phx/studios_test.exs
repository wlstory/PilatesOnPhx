defmodule PilatesOnPhx.StudiosTest do
  use ExUnit.Case, async: true

  alias Ash.Domain.Info, as: DomainInfo
  alias PilatesOnPhx.Studios

  describe "domain module structure" do
    test "module exists and is loadable" do
      assert Code.ensure_loaded?(Studios),
             "Studios domain module is not loadable"
    end

    test "module uses Ash.Domain" do
      assert function_exported?(Studios, :spark_is, 0),
             "Studios does not implement Ash.Domain behaviour"

      assert Studios.spark_is() == Ash.Domain,
             "Studios is not an Ash.Domain"
    end

    test "module has comprehensive documentation" do
      {:docs_v1, _, :elixir, _, module_doc, _, _} = Code.fetch_docs(Studios)

      refute module_doc == :none,
             "Studios domain has no @moduledoc"

      refute module_doc == :hidden,
             "Studios domain documentation is hidden"

      case module_doc do
        %{"en" => doc_content} ->
          assert String.length(doc_content) > 100,
                 "Studios @moduledoc is too brief (< 100 chars)"

          assert doc_content =~ "Studios" or doc_content =~ "studio",
                 "Documentation should mention domain name"

          assert doc_content =~ "location" or doc_content =~ "facility",
                 "Documentation should describe studio/location management"

          assert doc_content =~ "settings" or doc_content =~ "configuration",
                 "Documentation should describe studio configuration"

        _ ->
          flunk("Unexpected module_doc format: #{inspect(module_doc)}")
      end
    end

    test "declares resources list" do
      # Use DomainInfo.resources/1 to get resources
      resources = DomainInfo.resources(Studios)

      assert is_list(resources),
             "resources should return a list"

      # Studios domain now has 4 resources: Studio, StudioStaff, Room, Equipment
      assert length(resources) == 4,
             "Studios domain should have 4 registered resources"

      resource_modules = Enum.map(resources, & &1)

      assert PilatesOnPhx.Studios.Studio in resource_modules,
             "Studio resource should be registered"

      assert PilatesOnPhx.Studios.StudioStaff in resource_modules,
             "StudioStaff resource should be registered"

      assert PilatesOnPhx.Studios.Room in resource_modules,
             "Room resource should be registered"

      assert PilatesOnPhx.Studios.Equipment in resource_modules,
             "Equipment resource should be registered"
    end
  end

  describe "Ash.Domain callbacks" do
    test "domain info functions work correctly" do
      # Verify we can call DomainInfo functions on this domain
      assert is_list(DomainInfo.resources(Studios)),
             "DomainInfo.resources/1 should work on Studios domain"
    end

    test "domain configuration is valid" do
      # Verify domain has valid Spark DSL configuration
      resources = DomainInfo.resources(Studios)

      assert is_list(resources),
             "Domain should have valid resource configuration"
    end
  end

  describe "domain subdirectory structure" do
    test "studios subdirectory exists" do
      assert File.dir?("lib/pilates_on_phx/studios"),
             "Studios subdirectory does not exist"
    end

    test "subdirectory contains resource files" do
      # Studios domain should have resource implementations
      assert File.exists?("lib/pilates_on_phx/studios/studio.ex"),
             "Studio resource file should exist"

      assert File.exists?("lib/pilates_on_phx/studios/studio_staff.ex"),
             "StudioStaff resource file should exist"

      assert File.exists?("lib/pilates_on_phx/studios/room.ex"),
             "Room resource file should exist"

      assert File.exists?("lib/pilates_on_phx/studios/equipment.ex"),
             "Equipment resource file should exist"
    end
  end

  describe "domain responsibility boundaries" do
    test "module documentation describes correct domain scope" do
      {:docs_v1, _, :elixir, _, %{"en" => doc_content}, _, _} = Code.fetch_docs(Studios)

      # Studios should own studio entities and settings
      expected_concepts = [
        "studio"
      ]

      doc_lower = String.downcase(doc_content)

      Enum.each(expected_concepts, fn concept ->
        assert doc_lower =~ concept,
               "Studios documentation should mention '#{concept}'"
      end)
    end
  end
end
