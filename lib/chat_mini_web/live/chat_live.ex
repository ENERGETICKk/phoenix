defmodule ChatMiniWeb.ChatLive do
  use ChatMiniWeb, :live_view
  alias ChatMini.Chat
  alias ChatMini.Chat.Message
  alias ChatMini.Accounts

  def mount(_params, session, socket) do
    user_id = session["user_id"]
    current_user = Accounts.get_user!(user_id)

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:show_profile, false)
     |> assign(:profile_form, to_form(Accounts.change_user(current_user)))
     |> assign(:channels, Chat.list_channels())
     |> assign(:form, to_form(Chat.change_message(%Message{})))
     |> allow_upload(:avatar, accept: ~w(.jpg .jpeg .png), max_entries: 1, max_file_size: 10_000_000)}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    channel = Chat.get_channel!(id)
    if connected?(socket) do
       # Unsubscribe from previous channel if any
       if old_id = socket.assigns[:current_channel_id], do: Phoenix.PubSub.unsubscribe(ChatMini.PubSub, "chat:#{old_id}")
       Chat.subscribe(id)
    end

    {:noreply,
     socket
     |> assign(:current_channel, channel)
     |> assign(:current_channel_id, id)
     |> stream(:messages, Chat.list_messages(id), reset: true)}
  end

  def handle_params(_params, _uri, socket) do
    # Default to first channel (general)
    channel = List.first(socket.assigns.channels)
    {:noreply, push_patch(socket, to: ~p"/chat/#{channel.id}")}
  end

  # Eventos de Mensajes
  def handle_event("send_message", %{"message" => params}, socket) do
    params = params
      |> Map.put("username", socket.assigns.current_user.username)
      |> Map.put("avatar_url", socket.assigns.current_user.avatar_url)
      |> Map.put("channel_id", socket.assigns.current_channel_id)

    case Chat.create_message(params) do
      {:ok, _message} ->
        {:noreply, assign(socket, :form, to_form(Chat.change_message(%Message{})))}
      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("delete_message", %{"id" => id}, socket) do
    message = Chat.get_message!(id)
    if message.username == socket.assigns.current_user.username do
      Chat.delete_message(message)
    end
    {:noreply, socket}
  end

  # Eventos de Perfil
  def handle_event("toggle_profile", _, socket) do
    {:noreply, assign(socket, show_profile: !socket.assigns.show_profile)}
  end

  def handle_event("validate_profile", %{"user" => user_params}, socket) do
    changeset = socket.assigns.current_user |> Accounts.change_user(user_params) |> Map.put(:action, :validate)
    {:noreply, assign(socket, profile_form: to_form(changeset))}
  end

  def handle_event("save_profile", %{"user" => user_params}, socket) do
    avatar_url = consume_uploaded_entries(socket, :avatar, fn %{path: path}, entry ->
      ext = Path.extname(entry.client_name)
      file_name = "#{socket.assigns.current_user.id}_avatar#{ext}"
      dest = Path.join(["priv", "static", "uploads", file_name])
      File.cp!(path, dest)
      {:ok, "/uploads/#{file_name}"}
    end) |> List.first()

    user_params = if avatar_url, do: Map.put(user_params, "avatar_url", avatar_url), else: user_params

    case Accounts.update_user(socket.assigns.current_user, user_params) do
      {:ok, user} -> {:noreply, socket |> assign(current_user: user, show_profile: false) |> put_flash(:info, "Profile updated!")}
      {:error, changeset} -> {:noreply, assign(socket, profile_form: to_form(changeset))}
    end
  end

  # Real-time updates
  def handle_info({:message_created, message}, socket) do
    {:noreply, stream_insert(socket, :messages, message)}
  end

  def handle_info({:message_deleted, message}, socket) do
    {:noreply, stream_delete(socket, :messages, message)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex h-screen bg-[#313338] text-[#dbdee1] font-sans overflow-hidden relative">
      <!-- 1. Sidebar Servidores -->
      <div class="w-[72px] bg-[#1e1f22] flex flex-col items-center py-3 space-y-2 flex-shrink-0">
        <div class="w-12 h-12 bg-[#5865f2] rounded-[16px] flex items-center justify-center text-white cursor-pointer group relative">
          <svg class="w-7 h-7" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 14.5v-9l6 4.5-6 4.5z"/></svg>
        </div>
        <div class="mt-auto mb-4 space-y-4 flex flex-col items-center">
           <button phx-click="toggle_profile" class="w-12 h-12 bg-[#313338] rounded-[24px] hover:rounded-[16px] transition-all duration-200 flex items-center justify-center text-[#23a559] hover:bg-[#23a559] hover:text-white cursor-pointer group relative">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" /></svg>
           </button>
           <.link href={~p"/logout"} method="delete" class="w-12 h-12 bg-[#313338] rounded-[24px] hover:rounded-[16px] transition-all duration-200 flex items-center justify-center text-[#f23f42] hover:bg-[#f23f42] hover:text-white cursor-pointer relative group">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" /></svg>
           </.link>
        </div>
      </div>

      <!-- 2. Sidebar Canales -->
      <div class="w-60 bg-[#2b2d31] flex flex-col flex-shrink-0 hidden md:flex">
        <div class="h-12 px-4 border-b border-[#1f2124] flex items-center shadow-sm">
          <h1 class="font-bold text-white truncate text-sm">PHOENIX CHAT</h1>
        </div>
        <div class="flex-1 p-2 space-y-[2px] overflow-y-auto">
          <%= for channel <- @channels do %>
            <.link patch={~p"/chat/#{channel.id}"} class={"flex items-center gap-2 p-2 rounded cursor-pointer group #{if @current_channel_id == "#{channel.id}", do: "bg-[#3f4147] text-white", else: "text-[#949ba4] hover:bg-[#35373c] hover:text-[#dbdee1]"}"}>
              <span class="text-[#949ba4] text-xl">#</span>
              <span class="font-medium text-sm"><%= channel.name %></span>
            </.link>
          <% end %>
        </div>
        <div class="bg-[#232428] p-2 flex items-center gap-2 cursor-pointer hover:bg-[#35373c]" phx-click="toggle_profile">
           <div class="w-8 h-8 rounded-full bg-[#5865f2] overflow-hidden">
             <%= if @current_user.avatar_url do %><img src={@current_user.avatar_url} class="w-full h-full object-cover" /><% else %>
             <div class="w-full h-full flex items-center justify-center text-xs font-bold text-white"><%= String.at(@current_user.username, 0) |> String.upcase() %></div><% end %>
           </div>
           <div class="flex-1 min-w-0"><div class="text-xs font-bold text-white truncate"><%= @current_user.username %></div><div class="text-[10px] text-[#b5bac1] truncate">#<%= String.slice("#{ @current_user.id }", 0, 4) %></div></div>
        </div>
      </div>

      <!-- 3. Chat -->
      <div class="flex flex-col flex-1 min-w-0">
        <div class="h-12 px-4 border-b border-[#1f2124] flex items-center bg-[#313338] shadow-sm flex-shrink-0 gap-2">
           <span class="text-[#949ba4] text-2xl">#</span>
           <span class="font-bold text-white"><%= @current_channel.name %></span>
        </div>

        <div id="messages" phx-update="stream" phx-hook="ScrollDown" class="flex-1 overflow-y-auto p-4 space-y-1">
          <div :for={{dom_id, message} <- @streams.messages} id={dom_id} class="flex items-start gap-4 hover:bg-[#2e3035] -mx-4 px-4 py-[2px] group relative">
              <div class="w-10 h-10 rounded-full bg-[#5865f2] overflow-hidden mt-1 flex-shrink-0">
                <%= if message.avatar_url do %><img src={message.avatar_url} class="w-full h-full object-cover" /><% else %>
                <div class="w-full h-full flex items-center justify-center text-white font-bold"><%= String.at(message.username || "?", 0) |> String.upcase() %></div><% end %>
              </div>
              <div class="flex-1 min-w-0">
                <div class="flex items-baseline gap-2">
                  <span class="font-bold text-white hover:underline cursor-pointer"><%= message.username %></span>
                  <span class="text-[10px] text-[#949ba4] font-medium"><%= Calendar.strftime(message.inserted_at, "%H:%M") %></span>
                </div>
                <div class="text-[#dbdee1] text-[15px] break-words"><%= message.content %></div>
              </div>
              <!-- ACCIONES (HOVER) -->
              <div class="absolute -top-4 right-8 bg-[#313338] border border-[#1e1f22] rounded flex items-center p-1 shadow-lg opacity-0 group-hover:opacity-100 transition-opacity duration-100 z-10">
                 <button class="p-1 hover:bg-[#3f4147] rounded text-[#b5bac1] hover:text-white" title="Copy Message">
                   <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path d="M8 5H6a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2v-1M8 5a2 2 0 002 2h2a2 2 0 002-2M8 5a2 2 0 012-2h2a2 2 0 012 2m0 0h2a2 2 0 012 2v3m2 4H10m0 0l3-3m-3 3l3 3" /></svg>
                 </button>
                 <%= if message.username == @current_user.username do %>
                   <button phx-click="delete_message" phx-value-id={message.id} data-confirm="Delete message?" class="p-1 hover:bg-[#f23f42]/10 rounded text-[#b5bac1] hover:text-[#f23f42]" title="Delete">
                     <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" /></svg>
                   </button>
                 <% end %>
              </div>
          </div>
        </div>

        <div class="px-4 pb-6 pt-2 bg-[#313338]">
          <div class="bg-[#383a40] rounded-lg p-3">
            <.form for={@form} phx-submit="send_message" class="flex items-center gap-3">
              <input type="text" name="message[content]" placeholder={"Message ##{@current_channel.name}"} class="bg-transparent border-none focus:ring-0 p-0 flex-1 text-white placeholder-[#949ba4] outline-none" autocomplete="off" />
              <button type="submit" class="text-[#b5bac1] hover:text-white"><svg class="w-6 h-6 rotate-90" fill="currentColor" viewBox="0 0 24 24"><path d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z"></path></svg></button>
            </.form>
          </div>
        </div>
      </div>

      <!-- MODAL PERFIL -->
      <%= if @show_profile do %>
        <div class="absolute inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
          <div class="bg-[#2b2d31] w-full max-w-md rounded-lg shadow-2xl border border-[#1e1f22]" phx-click-away="toggle_profile">
            <div class="h-20 bg-[#5865f2] relative">
              <button phx-click="toggle_profile" class="absolute top-2 right-2 text-white hover:bg-black/20 rounded-full p-1"><svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path d="M6 18L18 6M6 6l12 12" /></svg></button>
              <div class="absolute -bottom-10 left-4 p-1 bg-[#2b2d31] rounded-full overflow-hidden">
                <div class="w-20 h-20 rounded-full bg-[#5865f2] border-4 border-[#2b2d31] flex items-center justify-center overflow-hidden">
                   <%= if @current_user.avatar_url do %><img src={@current_user.avatar_url} class="w-full h-full object-cover" /><% else %>
                   <span class="text-3xl font-bold text-white"><%= String.at(@current_user.username, 0) |> String.upcase() %></span><% end %>
                </div>
              </div>
            </div>
            <div class="pt-12 p-6 space-y-4">
              <h3 class="text-white font-bold uppercase text-sm">User Settings</h3>
              <.form for={@profile_form} phx-change="validate_profile" phx-submit="save_profile" class="space-y-4">
                <div class="bg-[#1e1f22] p-4 rounded-lg space-y-4">
                  <div>
                    <label class="block text-[11px] font-bold text-[#b5bac1] uppercase mb-2">Avatar</label>
                    <.live_file_input upload={@uploads.avatar} class="text-xs text-[#b5bac1]" />
                  </div>
                  <div><label class="block text-[11px] font-bold text-[#b5bac1] uppercase mb-2">Username</label><.input field={@profile_form[:username]} class="w-full bg-[#2b2d31] border-none rounded p-2 text-white outline-none" /></div>
                  <div><label class="block text-[11px] font-bold text-[#b5bac1] uppercase mb-2">Email</label><.input field={@profile_form[:email]} type="email" class="w-full bg-[#2b2d31] border-none rounded p-2 text-white outline-none" /></div>
                </div>
                <div class="flex justify-end gap-3"><button type="button" phx-click="toggle_profile" class="text-sm text-white">Cancel</button><button type="submit" class="bg-[#5865f2] hover:bg-[#4752c4] text-white px-6 py-2 rounded text-sm font-medium">Save Changes</button></div>
              </.form>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
