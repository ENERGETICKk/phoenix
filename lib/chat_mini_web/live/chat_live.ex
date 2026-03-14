defmodule ChatMiniWeb.ChatLive do
  use ChatMiniWeb, :live_view
  alias ChatMini.Chat
  alias ChatMini.Chat.Message
  alias ChatMini.Accounts

  def mount(_params, session, socket) do
    if connected?(socket), do: Chat.subscribe()

    user_id = session["user_id"]
    current_user = Accounts.get_user!(user_id)

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> stream(:messages, Chat.list_messages())
     |> assign(:form, to_form(Chat.change_message(%Message{})))}
  end

  def handle_event("send_message", %{"message" => params}, socket) do
    # Usamos el username del usuario logeado
    params = Map.put(params, "username", socket.assigns.current_user.username)

    case Chat.create_message(params) do
      {:ok, _message} ->
        {:noreply, assign(socket, :form, to_form(Chat.change_message(%Message{})))}
      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_info({:message_created, message}, socket) do
    {:noreply, stream_insert(socket, :messages, message)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex h-screen bg-[#313338] text-[#dbdee1] font-sans overflow-hidden">
      <!-- 1. Sidebar de Servidores -->
      <div class="w-[72px] bg-[#1e1f22] flex flex-col items-center py-3 space-y-2 flex-shrink-0">
        <div class="w-12 h-12 bg-[#5865f2] rounded-[16px] flex items-center justify-center text-white">
          <svg class="w-7 h-7" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 14.5v-9l6 4.5-6 4.5z"/></svg>
        </div>
        <div class="w-8 h-[2px] bg-[#35363c] rounded-full mx-4"></div>
        <div class="mt-auto mb-4">
           <.link href={~p"/logout"} method="delete" class="w-12 h-12 bg-[#313338] rounded-[24px] hover:rounded-[16px] transition-all duration-200 flex items-center justify-center text-[#f23f42] hover:bg-[#f23f42] hover:text-white cursor-pointer group" title="Logout">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" /></svg>
           </.link>
        </div>
      </div>

      <!-- 2. Sidebar de Canales -->
      <div class="w-60 bg-[#2b2d31] flex flex-col flex-shrink-0 hidden md:flex">
        <div class="h-12 px-4 border-b border-[#1f2124] flex items-center shadow-sm">
          <h1 class="font-bold text-white truncate">Phoenix Chat</h1>
        </div>
        <div class="flex-1 overflow-y-auto py-3 px-2 space-y-[2px]">
          <div class="flex items-center gap-2 p-2 rounded bg-[#3f4147] text-white cursor-pointer">
            <span class="text-[#949ba4] text-xl">#</span>
            <span class="font-medium">general</span>
          </div>
        </div>
        <!-- User Section Footer -->
        <div class="bg-[#232428] p-2 flex items-center gap-2">
           <div class="w-8 h-8 rounded-full bg-[#5865f2] flex items-center justify-center text-xs font-bold text-white">
             <%= String.at(@current_user.username, 0) |> String.upcase() %>
           </div>
           <div class="flex-1 min-w-0">
             <div class="text-xs font-bold text-white truncate"><%= @current_user.username %></div>
             <div class="text-[10px] text-[#b5bac1] truncate">#<%= String.slice("#{ @current_user.id }", 0, 4) %></div>
           </div>
        </div>
      </div>

      <!-- 3. Area de Chat Principal -->
      <div class="flex flex-col flex-1 min-w-0">
        <!-- Header -->
        <div class="h-12 px-4 border-b border-[#1f2124] flex items-center bg-[#313338] shadow-sm flex-shrink-0">
           <span class="text-[#949ba4] text-2xl mr-2">#</span>
           <span class="font-bold text-white mr-4">general</span>
        </div>

        <!-- Mensajes -->
        <div id="messages" phx-update="stream" phx-hook="ScrollDown" class="flex-1 overflow-y-auto p-4 space-y-1">
          <div :for={{dom_id, message} <- @streams.messages} id={dom_id} class="flex items-start gap-4 hover:bg-[#2e3035] -mx-4 px-4 py-[2px] group">
              <div class="w-10 h-10 rounded-full bg-[#5865f2] flex items-center justify-center text-white font-bold flex-shrink-0 mt-1">
                <%= String.at(message.username || "?", 0) |> String.upcase() %>
              </div>
              <div class="flex-1 min-w-0">
                <div class="flex items-baseline gap-2">
                  <span class="font-bold text-white hover:underline cursor-pointer"><%= message.username %></span>
                  <span class="text-[10px] text-[#949ba4] font-medium"><%= Calendar.strftime(message.inserted_at, "%H:%M") %></span>
                </div>
                <div class="text-[#dbdee1] text-[15px] leading-relaxed break-words"><%= message.content %></div>
              </div>
          </div>
        </div>

        <!-- Input Box -->
        <div class="px-4 pb-6 pt-2 bg-[#313338]">
          <div class="bg-[#383a40] rounded-lg p-3">
            <.form for={@form} phx-submit="send_message" class="flex items-center gap-3">
              <div class="bg-[#4e5058] rounded-full p-1 text-[#b5bac1] hover:text-white cursor-pointer">
                <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24"><path d="M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z"/></svg>
              </div>
              <input type="text" name="message[content]" placeholder={"Enviar mensaje a #general como #{@current_user.username}"} class="bg-transparent border-none focus:ring-0 p-0 flex-1 text-white placeholder-[#949ba4] shadow-none outline-none" autocomplete="off" />
              <button type="submit" class="text-[#b5bac1] hover:text-white transition-colors">
                 <svg class="w-6 h-6 rotate-90" fill="currentColor" viewBox="0 0 24 24"><path d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z"></path></svg>
              </button>
            </.form>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
