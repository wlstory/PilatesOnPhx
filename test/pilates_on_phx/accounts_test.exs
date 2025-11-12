defmodule PilatesOnPhx.AccountsTest do
  use ExUnit.Case, async: true

  alias Ash.Domain.Info, as: DomainInfo
  alias PilatesOnPhx.Accounts

  describe "domain module structure" do
    test "module exists and is loadable" do
      assert Code.ensure_loaded?(Accounts),
             "Accounts domain module is not loadable"
    end

    test "module uses Ash.Domain" do
      assert function_exported?(Accounts, :spark_is, 0),
             "Accounts does not implement Ash.Domain behaviour"

      assert Accounts.spark_is() == Ash.Domain,
             "Accounts is not an Ash.Domain"
    end

    test "module has comprehensive documentation" do
      {:docs_v1, _, :elixir, _, module_doc, _, _} = Code.fetch_docs(Accounts)

      refute module_doc == :none,
             "Accounts domain has no @moduledoc"

      refute module_doc == :hidden,
             "Accounts domain documentation is hidden"

      # Extract actual doc content
      case module_doc do
        %{"en" => doc_content} ->
          assert String.length(doc_content) > 100,
                 "Accounts @moduledoc is too brief (< 100 chars)"

          assert doc_content =~ "Accounts",
                 "Documentation should mention domain name"

          assert doc_content =~ "authentication" or doc_content =~ "auth",
                 "Documentation should describe authentication purpose"

          assert doc_content =~ "multi-tenant" or doc_content =~ "organization",
                 "Documentation should describe multi-tenant architecture"

        _ ->
          flunk("Unexpected module_doc format: #{inspect(module_doc)}")
      end
    end

    test "declares resources list" do
      # Use DomainInfo.resources/1 to get resources
      resources = DomainInfo.resources(Accounts)

      assert is_list(resources),
             "resources should return a list"

      # Should contain the core account resources
      assert length(resources) > 0,
             "Resources list should not be empty"

      expected_resources = [
        PilatesOnPhx.Accounts.User,
        PilatesOnPhx.Accounts.Organization,
        PilatesOnPhx.Accounts.Token,
        PilatesOnPhx.Accounts.OrganizationMembership
      ]

      Enum.each(expected_resources, fn resource ->
        assert resource in resources,
               "#{inspect(resource)} should be in domain resources"
      end)
    end
  end

  describe "Ash.Domain callbacks" do
    test "domain info functions work correctly" do
      # Verify we can call DomainInfo functions on this domain
      assert is_list(DomainInfo.resources(Accounts)),
             "DomainInfo.resources/1 should work on Accounts domain"
    end

    test "domain configuration is valid" do
      # Verify domain has valid Spark DSL configuration
      resources = DomainInfo.resources(Accounts)

      assert is_list(resources),
             "Domain should have valid resource configuration"
    end
  end

  describe "domain subdirectory structure" do
    test "accounts subdirectory exists" do
      assert File.dir?("lib/pilates_on_phx/accounts"),
             "Accounts subdirectory does not exist"
    end

    test "subdirectory is prepared for future resources" do
      gitkeep = "lib/pilates_on_phx/accounts/.gitkeep"

      assert File.exists?(gitkeep),
             ".gitkeep file not found in accounts subdirectory"
    end
  end

  describe "domain responsibility boundaries" do
    test "module documentation describes correct domain scope" do
      {:docs_v1, _, :elixir, _, %{"en" => doc_content}, _, _} = Code.fetch_docs(Accounts)

      # Accounts should own authentication and organizations
      expected_concepts = [
        "user",
        "token",
        "organization"
      ]

      doc_lower = String.downcase(doc_content)

      Enum.each(expected_concepts, fn concept ->
        assert doc_lower =~ concept,
               "Accounts documentation should mention '#{concept}'"
      end)
    end
  end
end
