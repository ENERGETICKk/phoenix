defmodule Contador.EstadisticasTest do
  use Contador.DataCase

  alias Contador.Estadisticas

  describe "contadores" do
    alias Contador.Estadisticas.Numero

    import Contador.EstadisticasFixtures

    @invalid_attrs %{valor: nil}

    test "list_contadores/0 returns all contadores" do
      numero = numero_fixture()
      assert Estadisticas.list_contadores() == [numero]
    end

    test "get_numero!/1 returns the numero with given id" do
      numero = numero_fixture()
      assert Estadisticas.get_numero!(numero.id) == numero
    end

    test "create_numero/1 with valid data creates a numero" do
      valid_attrs = %{valor: 42}

      assert {:ok, %Numero{} = numero} = Estadisticas.create_numero(valid_attrs)
      assert numero.valor == 42
    end

    test "create_numero/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Estadisticas.create_numero(@invalid_attrs)
    end

    test "update_numero/2 with valid data updates the numero" do
      numero = numero_fixture()
      update_attrs = %{valor: 43}

      assert {:ok, %Numero{} = numero} = Estadisticas.update_numero(numero, update_attrs)
      assert numero.valor == 43
    end

    test "update_numero/2 with invalid data returns error changeset" do
      numero = numero_fixture()
      assert {:error, %Ecto.Changeset{}} = Estadisticas.update_numero(numero, @invalid_attrs)
      assert numero == Estadisticas.get_numero!(numero.id)
    end

    test "delete_numero/1 deletes the numero" do
      numero = numero_fixture()
      assert {:ok, %Numero{}} = Estadisticas.delete_numero(numero)
      assert_raise Ecto.NoResultsError, fn -> Estadisticas.get_numero!(numero.id) end
    end

    test "change_numero/1 returns a numero changeset" do
      numero = numero_fixture()
      assert %Ecto.Changeset{} = Estadisticas.change_numero(numero)
    end
  end
end
