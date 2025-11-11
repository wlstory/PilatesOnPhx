defmodule PilatesOnPhx.Accounts do
  @moduledoc """
  The Accounts domain handles user authentication, roles, and multi-tenant organization management.

  This domain provides the security boundary and authentication foundation for the entire system.
  All operations in other domains require an authenticated actor from this domain.

  ## Resources

  - **User**: Authentication and role management (owner, instructor, client)
  - **Organization**: Top-level tenant isolation for multi-tenant architecture
  - **Token**: Auth token lifecycle (managed by AshAuthentication)

  ## Responsibilities

  - User authentication and session management
  - Role-based access control (RBAC)
  - Multi-tenant security boundary
  - Password reset and account recovery
  - User profile management
  - Organization membership and permissions

  ## Multi-Tenant Strategy

  This domain establishes the tenant context (organization) that all other domains
  reference for data isolation. Every user belongs to an organization, and operations
  in other domains are scoped to the user's organization through actor-based authorization.

  ## Authorization Patterns

  Resources in this domain use actor-based authorization to ensure users can only
  access data within their organization:

      policies do
        policy action_type(:read) do
          authorize_if actor_attribute_equals(:organization_id, :organization_id)
        end
      end

  ## Cross-Domain Interactions

  - **Studios Domain**: Studios belong to organizations
  - **Classes Domain**: Classes are created by users in an organization
  - **Bookings Domain**: Clients are associated with organizations

  ## Usage Examples

      # Create a new user (during signup)
      user =
        User
        |> Ash.Changeset.for_create(:register, %{
          email: "instructor@studio.com",
          password: "secure_password",
          organization_id: org.id
        })
        |> Ash.create!()

      # Authenticate a user
      {:ok, user} =
        User
        |> Ash.Changeset.for_action(:sign_in_with_password, %{
          email: "instructor@studio.com",
          password: "secure_password"
        })
        |> Ash.read_one()

      # Query users in an organization (with actor)
      users =
        User
        |> Ash.Query.filter(organization_id == ^org_id)
        |> Ash.read!(actor: current_user)
  """

  use Ash.Domain

  resources do
    resource PilatesOnPhx.Accounts.User
    resource PilatesOnPhx.Accounts.Organization
    resource PilatesOnPhx.Accounts.Token
    resource PilatesOnPhx.Accounts.OrganizationMembership
  end

  # Custom wrapper functions for backward compatibility with tests
  # These unwrap Ash.Error.Invalid to expose the changeset directly

  def create(changeset, opts \\ []) do
    case Ash.create(changeset, Keyword.put(opts, :domain, __MODULE__)) do
      {:error, %Ash.Error.Invalid{changeset: cs}} when not is_binary(cs) ->
        {:error, cs}
      other ->
        other
    end
  end

  def create!(changeset, opts \\ []) do
    Ash.create!(changeset, Keyword.put(opts, :domain, __MODULE__))
  end

  def update(changeset, opts \\ []) do
    case Ash.update(changeset, Keyword.put(opts, :domain, __MODULE__)) do
      {:error, %Ash.Error.Invalid{changeset: cs}} when not is_binary(cs) ->
        {:error, cs}
      other ->
        other
    end
  end

  def update!(changeset, opts \\ []) do
    Ash.update!(changeset, Keyword.put(opts, :domain, __MODULE__))
  end

  def destroy(record, opts \\ []) do
    Ash.destroy(record, Keyword.put(opts, :domain, __MODULE__))
  end

  def destroy!(record, opts \\ []) do
    Ash.destroy!(record, Keyword.put(opts, :domain, __MODULE__))
  end

  def read(query, opts \\ []) do
    Ash.read(query, Keyword.put(opts, :domain, __MODULE__))
  end

  def read!(query, opts \\ []) do
    Ash.read!(query, Keyword.put(opts, :domain, __MODULE__))
  end

  def read_one(query, opts \\ []) do
    Ash.read_one(query, Keyword.put(opts, :domain, __MODULE__))
  end

  def read_one!(query, opts \\ []) do
    Ash.read_one!(query, Keyword.put(opts, :domain, __MODULE__))
  end

end
