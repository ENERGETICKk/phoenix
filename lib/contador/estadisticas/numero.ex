defmodule Contador.Estadisticas.Numero do
  use Ecto.Schema
  import Ecto.Changeset

  schema "contadores" do
    field :valor, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(numero, attrs) do
    numero
    |> cast(attrs, [:valor])
    |> validate_required([:valor])
  end
end
