defmodule ChatMini.Repo.Migrations.AddAvatarUrlToMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :avatar_url, :string
    end
  end
end
