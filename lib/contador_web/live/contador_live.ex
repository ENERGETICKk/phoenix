defmodule ContadorWeb.ContadorLive do
  # 1. Usamos las herramientas de LiveView
  use ContadorWeb, :live_view

  # 2. Traemos tu lógica de base de datos (asegúrate que el nombre coincida con tu archivo en lib/contador/)

  # 3. La función MOUNT: Se ejecuta al cargar la página
  def mount(_params, _session, socket) do
      # Buscamos si ya existe un contador en la BD
      contador = case Contador.Estadisticas.list_contadores() do
        [primero | _rest] ->
          primero # Si existe, usamos ese

        [] ->
          # IMPORTANTE: Si está vacía, CREAMOS el registro en la BD
          {:ok, nuevo} = Contador.Estadisticas.create_numero(%{valor: 0})
          nuevo
      end

      {:ok, assign(socket, :contador, contador)}
    end

  # 4. Render: Lo que se ve en pantalla
  def render(assigns) do
    ~H"""
    <div style="text-align: center; margin-top: 50px; border: 1px solid #ccc; padding: 20px;">
      <h1>El valor es: <%= @contador.valor %></h1>
      <button phx-click="incrementar">Incrementar</button>
    </div>
    """
  end

  # 5. Evento: Cuando pulsas el botón
  def handle_event("incrementar", _params, socket) do
    # 1. Recuperamos el contador actual que tenemos en pantalla
    contador_actual = socket.assigns.contador

    # 2. Calculamos el nuevo valor
    nuevo_valor = contador_actual.valor + 1

    # 3. Llamamos a la base de datos para guardar
    # update_numero/2 espera el struct original y un mapa con los cambios
    {:ok, contador_actualizado} = Contador.Estadisticas.update_numero(contador_actual, %{valor: nuevo_valor})

    # 4. Actualizamos el socket con el dato que nos devolvió la BD
    {:noreply, assign(socket, :contador, contador_actualizado)}
  end
end
