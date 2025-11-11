defmodule PilatesOnPhx.BookingsTest do
  use ExUnit.Case, async: true

  alias Ash.Domain.Info, as: DomainInfo
  alias PilatesOnPhx.Bookings

  describe "domain module structure" do
    test "module exists and is loadable" do
      assert Code.ensure_loaded?(Bookings),
             "Bookings domain module is not loadable"
    end

    test "module uses Ash.Domain" do
      assert function_exported?(Bookings, :spark_is, 0),
             "Bookings does not implement Ash.Domain behaviour"

      assert Bookings.spark_is() == Ash.Domain,
             "Bookings is not an Ash.Domain"
    end

    test "module has comprehensive documentation" do
      {:docs_v1, _, :elixir, _, module_doc, _, _} = Code.fetch_docs(Bookings)

      refute module_doc == :none,
             "Bookings domain has no @moduledoc"

      refute module_doc == :hidden,
             "Bookings domain documentation is hidden"

      case module_doc do
        %{"en" => doc_content} ->
          assert String.length(doc_content) > 100,
                 "Bookings @moduledoc is too brief (< 100 chars)"

          assert doc_content =~ "Bookings" or doc_content =~ "booking",
                 "Documentation should mention domain name"

          assert doc_content =~ "client" or doc_content =~ "customer",
                 "Documentation should describe client management"

          assert doc_content =~ "package" or doc_content =~ "credit",
                 "Documentation should describe package/credit system"

          assert doc_content =~ "waitlist",
                 "Documentation should describe waitlist functionality"

        _ ->
          flunk("Unexpected module_doc format: #{inspect(module_doc)}")
      end
    end

    test "declares resources list" do
      # Use DomainInfo.resources/1 to get resources
      resources = DomainInfo.resources(Bookings)

      assert is_list(resources),
             "resources should return a list"

      assert resources == [],
             "Resources list should be empty initially"
    end
  end

  describe "Ash.Domain callbacks" do
    test "domain info functions work correctly" do
      # Verify we can call DomainInfo functions on this domain
      assert is_list(DomainInfo.resources(Bookings)),
             "DomainInfo.resources/1 should work on Bookings domain"
    end

    test "domain configuration is valid" do
      # Verify domain has valid Spark DSL configuration
      resources = DomainInfo.resources(Bookings)

      assert is_list(resources),
             "Domain should have valid resource configuration"
    end
  end

  describe "domain subdirectory structure" do
    test "bookings subdirectory exists" do
      assert File.dir?("lib/pilates_on_phx/bookings"),
             "Bookings subdirectory does not exist"
    end

    test "subdirectory is prepared for future resources" do
      gitkeep = "lib/pilates_on_phx/bookings/.gitkeep"

      assert File.exists?(gitkeep),
             ".gitkeep file not found in bookings subdirectory"
    end
  end

  describe "domain responsibility boundaries" do
    test "module documentation describes correct domain scope" do
      {:docs_v1, _, :elixir, _, %{"en" => doc_content}, _, _} = Code.fetch_docs(Bookings)

      # Bookings should own clients, packages, bookings, and waitlists
      expected_concepts = [
        "client",
        "booking",
        "package",
        "waitlist"
      ]

      doc_lower = String.downcase(doc_content)

      Enum.each(expected_concepts, fn concept ->
        assert doc_lower =~ concept,
               "Bookings documentation should mention '#{concept}'"
      end)
    end
  end
end
