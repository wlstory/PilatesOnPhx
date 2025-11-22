defmodule PilatesOnPhx.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :pilates_on_phx

  def migrate do
    IO.puts("==> Starting migration process")
    load_app()

    for repo <- repos() do
      IO.puts("==> Running migrations for #{inspect(repo)}")
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end

    IO.puts("==> Migrations completed successfully")
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    IO.puts("==> Loading application")
    Application.load(@app)
  end
end
