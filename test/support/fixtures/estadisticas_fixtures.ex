defmodule Contador.EstadisticasFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Contador.Estadisticas` context.
  """

  @doc """
  Generate a numero.
  """
  def numero_fixture(attrs \\ %{}) do
    {:ok, numero} =
      attrs
      |> Enum.into(%{
        valor: 42
      })
      |> Contador.Estadisticas.create_numero()

    numero
  end
end
