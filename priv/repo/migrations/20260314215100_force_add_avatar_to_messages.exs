defmodule ChatMini.Repo.Migrations.ForceAddAvatarToMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :avatar_url, :string
    end
  end
end
