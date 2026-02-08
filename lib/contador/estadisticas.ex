defmodule Contador.Estadisticas do
  @moduledoc """
  The Estadisticas context.
  """

  import Ecto.Query, warn: false
  alias Contador.Repo

  alias Contador.Estadisticas.Numero

  @doc """
  Returns the list of contadores.

  ## Examples

      iex> list_contadores()
      [%Numero{}, ...]

  """
  def list_contadores do
    Repo.all(Numero)
  end

  @doc """
  Gets a single numero.

  Raises `Ecto.NoResultsError` if the Numero does not exist.

  ## Examples

      iex> get_numero!(123)
      %Numero{}

      iex> get_numero!(456)
      ** (Ecto.NoResultsError)

  """
  def get_numero!(id), do: Repo.get!(Numero, id)

  @doc """
  Creates a numero.

  ## Examples

      iex> create_numero(%{field: value})
      {:ok, %Numero{}}

      iex> create_numero(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_numero(attrs) do
    %Numero{}
    |> Numero.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a numero.

  ## Examples

      iex> update_numero(numero, %{field: new_value})
      {:ok, %Numero{}}

      iex> update_numero(numero, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_numero(%Numero{} = numero, attrs) do
    numero
    |> Numero.changeset(attrs)
    |> Repo.update()
  end



  @doc """
  Esta funcion es la primera que creare, creo que sera simple y me estiy ayudando de codigo externo
  Sera una funcion simple que desde un boton, lo que hara es coger el valor de numero
  y sumarle 1,, luego validara y guardara en la bbdd Repo.update()
  """

  def suma_numero (%Numero{} = numero) do
    nuevo_valor = numero.valor + 1
    update_numero(numero, %{valor: nuevo_valor})
  end


  @doc """
  Deletes a numero.

  ## Examples

      iex> delete_numero(numero)
      {:ok, %Numero{}}

      iex> delete_numero(numero)
      {:error, %Ecto.Changeset{}}

  """
  def delete_numero(%Numero{} = numero) do
    Repo.delete(numero)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking numero changes.

  ## Examples

      iex> change_numero(numero)
      %Ecto.Changeset{data: %Numero{}}

  """
  def change_numero(%Numero{} = numero, attrs \\ %{}) do
    Numero.changeset(numero, attrs)
  end



end
