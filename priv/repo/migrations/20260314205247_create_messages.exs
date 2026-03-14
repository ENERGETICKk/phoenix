defmodule ChatMini.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :content, :text
      add :username, :string

      timestamps(type: :utc_datetime)
    end
  end
end
