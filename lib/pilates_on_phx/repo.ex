defmodule PilatesOnPhx.Repo do
  use Ecto.Repo,
    otp_app: :pilates_on_phx,
    adapter: Ecto.Adapters.Postgres
end
