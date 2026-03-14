defmodule ChatMini.Repo.Migrations.AddChannelIdToMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :channel_id, references(:channels, on_delete: :nothing)
    end
    create index(:messages, [:channel_id])
  end
end
