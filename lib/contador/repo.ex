defmodule Contador.Repo do
  use Ecto.Repo,
    otp_app: :contador,
    adapter: Ecto.Adapters.Postgres
end
