defmodule PilatesOnPhx.ClassesTest do
  use ExUnit.Case, async: true

  alias Ash.Domain.Info, as: DomainInfo
  alias PilatesOnPhx.Classes

  describe "domain module structure" do
    test "module exists and is loadable" do
      assert Code.ensure_loaded?(Classes),
             "Classes domain module is not loadable"
    end

    test "module uses Ash.Domain" do
      assert function_exported?(Classes, :spark_is, 0),
             "Classes does not implement Ash.Domain behaviour"

      assert Classes.spark_is() == Ash.Domain,
             "Classes is not an Ash.Domain"
    end

    test "module has comprehensive documentation" do
      {:docs_v1, _, :elixir, _, module_doc, _, _} = Code.fetch_docs(Classes)

      refute module_doc == :none,
             "Classes domain has no @moduledoc"

      refute module_doc == :hidden,
             "Classes domain documentation is hidden"

      case module_doc do
        %{"en" => doc_content} ->
          assert String.length(doc_content) > 100,
                 "Classes @moduledoc is too brief (< 100 chars)"

          assert doc_content =~ "Classes" or doc_content =~ "class",
                 "Documentation should mention domain name"

          assert doc_content =~ "schedule" or doc_content =~ "session",
                 "Documentation should describe scheduling functionality"

          assert doc_content =~ "attendance" or doc_content =~ "check-in",
                 "Documentation should describe attendance tracking"

        _ ->
          flunk("Unexpected module_doc format: #{inspect(module_doc)}")
      end
    end

    test "declares resources list" do
      # Use DomainInfo.resources/1 to get resources
      resources = DomainInfo.resources(Classes)

      assert is_list(resources),
             "resources should return a list"

      assert resources == [],
             "Resources list should be empty initially"
    end
  end

  describe "Ash.Domain callbacks" do
    test "domain info functions work correctly" do
      # Verify we can call DomainInfo functions on this domain
      assert is_list(DomainInfo.resources(Classes)),
             "DomainInfo.resources/1 should work on Classes domain"
    end

    test "domain configuration is valid" do
      # Verify domain has valid Spark DSL configuration
      resources = DomainInfo.resources(Classes)

      assert is_list(resources),
             "Domain should have valid resource configuration"
    end
  end

  describe "domain subdirectory structure" do
    test "classes subdirectory exists" do
      assert File.dir?("lib/pilates_on_phx/classes"),
             "Classes subdirectory does not exist"
    end

    test "subdirectory is prepared for future resources" do
      gitkeep = "lib/pilates_on_phx/classes/.gitkeep"

      assert File.exists?(gitkeep),
             ".gitkeep file not found in classes subdirectory"
    end
  end

  describe "domain responsibility boundaries" do
    test "module documentation describes correct domain scope" do
      {:docs_v1, _, :elixir, _, %{"en" => doc_content}, _, _} = Code.fetch_docs(Classes)

      # Classes should own class types, schedules, and attendance
      expected_concepts = [
        "class",
        "schedule",
        "attendance"
      ]

      doc_lower = String.downcase(doc_content)

      Enum.each(expected_concepts, fn concept ->
        assert doc_lower =~ concept,
               "Classes documentation should mention '#{concept}'"
      end)
    end
  end
end
