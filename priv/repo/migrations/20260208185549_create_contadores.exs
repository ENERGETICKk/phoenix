defmodule Contador.Repo.Migrations.CreateContadores do
  use Ecto.Migration

  def change do
    create table(:contadores) do
      add :valor, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
