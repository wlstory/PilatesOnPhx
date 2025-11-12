defmodule PilatesOnPhx.Bookings do
  @moduledoc """
  The Bookings domain manages the complete booking workflow including clients, packages,
  class reservations, waitlists, and payments.

  This is the core business domain where clients purchase packages, book classes, manage
  waitlists, and process payments. All resources in this domain are tightly coupled as
  they participate in the atomic booking transaction workflow.

  ## Resources

  - **Client**: Client profiles, preferences, and booking history
  - **Package**: Credit packages and membership offerings
  - **ClientPackage**: Client's purchased package instances with credit tracking
  - **Booking**: Class reservations consuming package credits
  - **Waitlist**: Queue entries when classes reach capacity
  - **Payment**: Payment records for package purchases

  ## Responsibilities

  - Client profile and preference management
  - Package definition and pricing
  - Package purchase and credit allocation
  - Class booking with automatic credit deduction
  - Waitlist management and automatic promotion
  - Payment processing and transaction records
  - Booking cancellation and credit refund
  - Late cancellation penalty enforcement
  - Package expiration tracking

  ## High Cohesion Rationale

  All resources in this domain are co-located because they form an inseparable workflow:
  - Clients purchase packages (atomic transaction)
  - Packages allocate credits to ClientPackage
  - Bookings consume credits from ClientPackage (atomic)
  - Waitlist promotion triggers booking creation
  - Payments link to package purchases

  Separating these would create complex distributed transactions and tight coupling
  across domain boundaries.

  ## Multi-Tenant Strategy

  Clients belong to organizations (through studio association). All booking operations
  are scoped to the user's organization:

      policies do
        policy action_type(:read) do
          authorize_if expr(organization_id == ^actor(:organization_id))
        end

        policy action_type(:create) do
          authorize_if relates_to_actor_via(:studio, :organization_id)
        end
      end

  ## Authorization Patterns

  - **Owners**: Full access to all bookings in their organization
  - **Instructors**: Read access to bookings for their classes
  - **Clients**: Read/write access to their own bookings only

  ## Atomic Operations

  Critical workflows that must remain atomic within this domain:

      # Book a class (atomic: check credits, create booking, deduct credits)
      {:ok, booking} = Bookings.book_class(client, session, package)

      # Cancel with refund (atomic: cancel booking, refund credits)
      {:ok, booking} = Bookings.cancel_booking(booking, refund: true)

      # Purchase package (atomic: create payment, allocate credits)
      {:ok, client_package} = Bookings.purchase_package(client, package, payment_method)

  ## Cross-Domain Interactions

  - **Studios Domain**: Clients associate with studios, bookings reference studios
  - **Classes Domain**: Bookings reference class sessions
  - **Accounts Domain**: Clients link to user accounts (optional)

  ## Usage Examples

      # Create a client profile
      client =
        Client
        |> Ash.Changeset.for_create(:create, %{
          name: "Jane Doe",
          email: "jane@example.com",
          phone: "555-0123",
          studio_id: studio.id
        }, actor: owner)
        |> Ash.create!()

      # Define a package
      package =
        Package
        |> Ash.Changeset.for_create(:create, %{
          name: "10 Class Pack",
          credits: 10,
          price_cents: 15000,
          validity_days: 90,
          studio_id: studio.id
        }, actor: owner)
        |> Ash.create!()

      # Purchase package
      client_package =
        ClientPackage
        |> Ash.Changeset.for_create(:purchase, %{
          client_id: client.id,
          package_id: package.id,
          credits_remaining: package.credits,
          expires_at: Date.add(Date.utc_today(), package.validity_days)
        }, actor: client)
        |> Ash.create!()

      # Book a class
      booking =
        Booking
        |> Ash.Changeset.for_create(:book_class, %{
          client_id: client.id,
          session_id: session.id,
          client_package_id: client_package.id
        }, actor: client)
        |> Ash.create!()

      # Add to waitlist (when class is full)
      waitlist_entry =
        Waitlist
        |> Ash.Changeset.for_create(:join, %{
          client_id: client.id,
          session_id: session.id
        }, actor: client)
        |> Ash.create!()

      # Query client's upcoming bookings
      upcoming_bookings =
        Booking
        |> Ash.Query.filter(
          client_id == ^client.id and
          session.start_time >= ^DateTime.utc_now()
        )
        |> Ash.Query.load(:session)
        |> Ash.read!(actor: client)
  """

  use Ash.Domain

  resources do
    # Resources will be added in subsequent issues (PHX-5)
    # - PilatesOnPhx.Bookings.Client
    # - PilatesOnPhx.Bookings.Package
    # - PilatesOnPhx.Bookings.ClientPackage
    # - PilatesOnPhx.Bookings.Booking
    # - PilatesOnPhx.Bookings.Waitlist
    # - PilatesOnPhx.Bookings.Payment
  end
end
