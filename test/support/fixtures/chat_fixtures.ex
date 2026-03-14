defmodule ChatMini.ChatFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ChatMini.Chat` context.
  """

  @doc """
  Generate a message.
  """
  def message_fixture(attrs \\ %{}) do
    {:ok, message} =
      attrs
      |> Enum.into(%{
        content: "some content",
        username: "some username"
      })
      |> ChatMini.Chat.create_message()

    message
  end
end
