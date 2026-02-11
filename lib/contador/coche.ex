defmodule Contador.Coche do
  defstruct velocidad: 0, rpm: 0, encendido: false

  # Caso 1: Coche apagado
  # def acelerar(%{encendido: false}) do
  #   {:error, "El coche está apagado. ¡Enciéndelo primero!"}
  # end

  # # Caso 2: Velocidad límite (Caso Base de la recursión)
  # def acelerar(%{velocidad: 100} = coche) do
  #   IO.puts("¡Velocidad máxima alcanzada!")
  #   coche
  # end

  # # Caso 3: Acelerando (Paso recursivo)
  # def acelerar(%{velocidad: velocidad} = coche) when velocidad < 100 do
  #   IO.puts("Velocidad actual: #{velocidad} -> Acelerando...")
  #   nuevo_coche = %{coche | velocidad: velocidad + 10}
  #   Process.sleep(500)
  #   acelerar(nuevo_coche)
  # end


  def acelerar(%{encendido: true, velocidad: v} = coche) when v < 100 do
    %{coche | velocidad: v + 10, rpm: (v + 10) * 20}
  end

  def acelerar(coche), do: coche
  def encender(coche), do: %{coche | encendido: true, rpm: 800}
end

coche = %{velocidad: 0, rpm: 0, encendido: true}
Contador.Coche.acelerar(coche)
