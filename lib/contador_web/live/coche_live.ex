defmodule ContadorWeb.CocheLive do
  use ContadorWeb, :live_view
  alias Contador.Coche

  def mount(_params, _session, socket) do
    # Iniciamos con un coche nuevo por defecto
    {:ok, assign(socket, :coche, %Coche{})}
  end

  def render(assigns) do
    ~H"""
    <div style="max-width: 400px; margin: 50px auto; font-family: monospace;">
      <h1>Simulador Telemetría</h1>

      <!-- El Tablero -->
      <div style="border: 2px solid #333; padding: 20px; border-radius: 10px;">
        <p>Estado: <strong><%= if @coche.encendido, do: "🟢 ON", else: "🔴 OFF" %></strong></p>
        <p>Velocidad: <%= @coche.velocidad %> km/h</p>
        <p>RPM: <%= @coche.rpm %></p>

        <!-- Barra visual de RPM -->
        <div style={"background: #eee; width: 100%; height: 20px;"}>
          <div style={"background: red; width: #{@coche.velocidad}%; height: 100%; transition: width 0.2s;"}></div>
        </div>
      </div>

      <!-- Los Controles -->
      <div style="margin-top: 20px; display: flex; gap: 10px;">
        <button phx-click="encender" disabled={@coche.encendido} style="background-color: #4CAF50; color: white; padding: 10px;">Arrancar Motor</button>
        <button phx-click="acelerar" disabled={!@coche.encendido} style="background-color: #FF9800; color: white; padding: 10px;">Acelerar (+10)</button>
        <button phx-click="detener" disabled={!@coche.encendido} style="background-color: #f44336; color: white; padding: 10px;">Detener Motor</button>
      </div>
    </div>
    """
  end

  def handle_event("encender", _, socket) do
    {:noreply, assign(socket, :coche, Coche.encender(socket.assigns.coche))}
  end

  def handle_event("acelerar", _, socket) do
    {:noreply, assign(socket, :coche, Coche.acelerar(socket.assigns.coche))}
  end
end
