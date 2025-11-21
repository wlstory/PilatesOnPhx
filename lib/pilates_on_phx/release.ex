defmodule PilatesOnPhx.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :pilates_on_phx

  require Logger

  def migrate do
    Logger.info("Starting migration process...")

    load_app()
    Logger.info("Application loaded successfully")

    repos = repos()
    Logger.info("Found #{length(repos)} repo(s): #{inspect(repos)}")

    for repo <- repos do
      Logger.info("Running migrations for repo: #{inspect(repo)}")

      case Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true)) do
        {:ok, _return, _apps} ->
          Logger.info("Migrations completed successfully for #{inspect(repo)}")

        {:error, reason} ->
          Logger.error("Migration failed for #{inspect(repo)}: #{inspect(reason)}")
          System.halt(1)
      end
    end

    Logger.info("All migrations completed successfully")
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Logger.info("Loading application configuration...")

    # Load the application without starting it
    Application.load(@app)
    Logger.info("Application spec loaded")

    # Start required dependencies for database connection
    {:ok, _} = Application.ensure_all_started(:ssl)
    Logger.info("SSL started")

    {:ok, _} = Application.ensure_all_started(:postgrex)
    Logger.info("Postgrex started")

    {:ok, _} = Application.ensure_all_started(:ecto_sql)
    Logger.info("Ecto SQL started")
  end
end
