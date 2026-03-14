defmodule ChatMini.Repo do
  use Ecto.Repo,
    otp_app: :chat_mini,
    adapter: Ecto.Adapters.Postgres
end
