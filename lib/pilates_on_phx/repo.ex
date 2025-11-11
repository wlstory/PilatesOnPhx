defmodule PilatesOnPhx.Repo do
  use Ecto.Repo,
    otp_app: :pilates_on_phx,
    adapter: Ecto.Adapters.Postgres

  use AshPostgres.Repo, fragments: []

  @impl AshPostgres.Repo
  def installed_extensions do
    ["uuid-ossp", "citext"]
  end

  @impl AshPostgres.Repo
  def min_pg_version do
    %Version{major: 16, minor: 0, patch: 0}
  end
end
