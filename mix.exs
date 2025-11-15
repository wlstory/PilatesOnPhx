defmodule PilatesOnPhx.MixProject do
  use Mix.Project

  def project do
    [
      app: :pilates_on_phx,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      listeners: listeners(Mix.env()),
      consolidate_protocols: Mix.env() != :dev,
      test_coverage: [
        summary: [threshold: 90],
        ignore_modules: [
          # Ignore all Inspect modules
          ~r/^Inspect\./,
          # Ignore framework/infrastructure modules with no business logic
          PilatesOnPhxWeb.ErrorHTML,
          PilatesOnPhx.Repo,
          PilatesOnPhxWeb.Telemetry,
          # Ignore Ash Domain macro modules (no actual code)
          # Top-level domain modules
          ~r/^PilatesOnPhx\.\w+$/
        ]
      ],
      dialyzer: dialyzer()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {PilatesOnPhx.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  def cli do
    [
      preferred_envs: [precommit: :test]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies which listeners to load per environment.
  defp listeners(:dev), do: [Phoenix.CodeReloader]
  defp listeners(_), do: []

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      # Core Ash Framework
      {:ash, "~> 3.7"},
      {:ash_admin, "~> 0.13.20"},
      {:ash_ai, "~> 0.2"},
      {:ash_archival, "~> 2.0.2"},
      {:ash_authentication, "~> 4.12"},
      {:ash_authentication_phoenix, "~> 2.12.1"},
      {:ash_cloak, "~> 0.1.7"},
      {:ash_events, "~> 0.5"},
      {:ash_oban, "~> 0.4"},
      {:ash_paper_trail, "~> 0.5.7"},
      {:ash_phoenix, "~> 2.3.17"},
      {:ash_postgres, "~> 2.6.23"},
      {:ash_state_machine, "~> 0.2"},

      # Core Phoenix & Ecto
      {:bandit, "~> 1.8"},
      {:dns_cluster, "~> 0.2.0"},
      {:ecto_sql, "~> 3.13"},
      {:gettext, "~> 0.26"},
      {:jason, "~> 1.2"},
      {:phoenix, "~> 1.8.1"},
      {:phoenix_ecto, "~> 4.5"},
      {:phoenix_html, "~> 4.3"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:phoenix_live_view, "~> 1.1.16"},
      {:postgrex, ">= 0.0.0"},
      {:resend, "~> 0.4.4"},
      {:swoosh, "~> 1.19.8"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},

      # Utilities & Other Libraries
      {:cloak, "~> 1.0"},
      {:igniter, "~> 0.6"},
      {:oban, "~> 2.20.1"},
      {:oban_web, "~> 2.11.6"},
      {:picosat_elixir, "~> 0.2"},
      {:req, "~> 0.5"},
      {:sourceror, "~> 1.8"},
      {:usage_rules, "~> 0.1.25"},

      # Assets
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:tailwind, "~> 0.4.1", runtime: Mix.env() == :dev},

      # Development only
      {:dotenvy, "~> 1.1", only: [:dev], runtime: false},
      {:phoenix_live_reload, "~> 1.6.1", only: :dev},

      # Test only
      {:lazy_html, "~> 0.1.8", only: :test},
      {:mox, "~> 1.2", only: :test},

      # Development & Test (Code Quality)
      {:credo, "~> 1.7.13", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.14.1", only: [:dev, :test], runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ash.setup", "assets.setup", "assets.build", "run priv/repo/seeds.exs"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ash.setup --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind pilates_on_phx", "esbuild pilates_on_phx"],
      "assets.deploy": [
        "tailwind pilates_on_phx --minify",
        "esbuild pilates_on_phx --minify",
        "phx.digest"
      ],
      precommit: [
        "compile --warnings-as-errors",
        "deps.unlock --check-unused",
        "format",
        "credo --strict",
        "sobelow --config --exit",
        "deps.audit --exit",
        "dialyzer --plt",
        "test --cover"
      ]
    ]
  end

  # Dialyzer configuration
  defp dialyzer do
    [
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
      plt_add_apps: [
        :ash,
        :ash_admin,
        :ash_authentication,
        :ash_authentication_phoenix,
        :ash_oban,
        :ash_phoenix,
        :ash_postgres,
        :dialyzer,
        :ecto,
        :ecto_sql,
        :elixir,
        :ex_unit,
        :gettext,
        :jason,
        :kernel,
        :logger,
        :mix,
        :oban,
        :oban_web,
        :phoenix,
        :phoenix_ecto,
        :phoenix_html,
        :phoenix_live_dashboard,
        :phoenix_live_view,
        :phoenix_pubsub,
        :plug,
        :spark,
        :stdlib,
        :swoosh,
        :telemetry,
        :telemetry_metrics
      ],
      ignore_warnings: ".dialyzer_ignore.exs"
    ]
  end
end
