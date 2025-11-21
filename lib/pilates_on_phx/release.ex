defmodule PilatesOnPhx.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :pilates_on_phx

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    # Load the application without starting it
    Application.load(@app)
    # Start required dependencies for database connection
    Application.ensure_all_started(:ssl)
    Application.ensure_all_started(:postgrex)
    Application.ensure_all_started(:ecto_sql)
  end
end
