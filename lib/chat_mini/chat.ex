defmodule ChatMini.Chat do
  @moduledoc """
  The Chat context.
  """

  import Ecto.Query, warn: false
  alias ChatMini.Repo

  alias ChatMini.Chat.Message
  alias ChatMini.Chat.Channel

  def list_channels do
    Repo.all(Channel)
  end

  def get_channel!(id), do: Repo.get!(Channel, id)

  def list_messages(channel_id) do
    Message
    |> where(channel_id: ^channel_id)
    |> order_by(asc: :inserted_at)
    |> Repo.all()
  end

  def subscribe(channel_id) do
    Phoenix.PubSub.subscribe(ChatMini.PubSub, "chat:#{channel_id}")
  end

  defp broadcast({:ok, message} = result, event) do
    Phoenix.PubSub.broadcast(ChatMini.PubSub, "chat:#{message.channel_id}", {event, message})
    result
  end

  defp broadcast(result, _event), do: result

  def get_message!(id), do: Repo.get!(Message, id)

  def create_message(attrs) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
    |> broadcast(:message_created)
  end

  def delete_message(%Message{} = message) do
    message
    |> Repo.delete()
    |> broadcast(:message_deleted)
  end

  def change_message(%Message{} = message, attrs \\ %{}) do
    Message.changeset(message, attrs)
  end
end
