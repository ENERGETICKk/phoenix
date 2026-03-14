defmodule ChatMini.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :content, :string
    field :username, :string
    field :avatar_url, :string
    belongs_to :channel, ChatMini.Chat.Channel

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :username, :avatar_url, :channel_id])
    |> validate_required([:content, :username, :channel_id])
  end
end
