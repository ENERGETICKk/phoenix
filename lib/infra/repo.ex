defmodule Infra.Repo do
  use Ecto.Repo,
    otp_app: :infra,
    adapter: Ecto.Adapters.Postgres
end
