[
  import_deps: [:ash, :ash_postgres, :ash_phoenix, :ecto, :ecto_sql, :phoenix],
  subdirectories: [
    "priv/*/migrations",
    "lib/pilates_on_phx/accounts",
    "lib/pilates_on_phx/studios",
    "lib/pilates_on_phx/classes",
    "lib/pilates_on_phx/bookings"
  ],
  plugins: [Phoenix.LiveView.HTMLFormatter],
  inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}", "priv/*/seeds.exs"]
]
