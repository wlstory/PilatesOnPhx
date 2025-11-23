defmodule PilatesOnPhx.Repo.Migrations.AddBusinessHoursToStudios do
  use Ecto.Migration

  def change do
    alter table(:studios) do
      add :regular_hours, :map, default: %{}
      add :special_hours, {:array, :map}, default: []
    end
  end
end
