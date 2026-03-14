defmodule ChatMiniWeb.ChatLive do
  use ChatMiniWeb, :live_view
  alias ChatMini.Chat
  alias ChatMini.Chat.Message
  alias ChatMini.Accounts
  alias ChatMini.Accounts.User

  def mount(_params, session, socket) do
    if connected?(socket), do: Chat.subscribe()

    user_id = session["user_id"]
    current_user = Accounts.get_user!(user_id)

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:show_profile, false)
     |> assign(:profile_form, to_form(Accounts.change_user(current_user)))
     |> stream(:messages, Chat.list_messages())
     |> assign(:form, to_form(Chat.change_message(%Message{})))
     |> allow_upload(:avatar, 
        accept: ~w(.jpg .jpeg .png), 
        max_entries: 1,
        max_file_size: 10_000_000)}
  end

  # Mensajes
  def handle_event("send_message", %{"message" => params}, socket) do
    # Usamos el avatar_url actual del usuario si existe
    params = params
      |> Map.put("username", socket.assigns.current_user.username)
      |> Map.put("avatar_url", socket.assigns.current_user.avatar_url)

    case Chat.create_message(params) do
      {:ok, _message} ->
        {:noreply, assign(socket, :form, to_form(Chat.change_message(%Message{})))}
      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  # Perfil
  def handle_event("toggle_profile", _, socket) do
    {:noreply, assign(socket, show_profile: !socket.assigns.show_profile)}
  end

  def handle_event("validate_profile", %{"user" => user_params}, socket) do
    changeset = 
      socket.assigns.current_user
      |> Accounts.change_user(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, profile_form: to_form(changeset))}
  end

  def handle_event("save_profile", %{"user" => user_params}, socket) do
    # 1. Consumir archivos subidos (si hay)
    avatar_url = 
      consume_uploaded_entries(socket, :avatar, fn %{path: path}, entry ->
        ext = Path.extname(entry.client_name)
        file_name = "#{socket.assigns.current_user.id}_avatar#{ext}"
        dest = Path.join(["priv", "static", "uploads", file_name])
        File.cp!(path, dest)
        {:ok, "/uploads/#{file_name}"}
      end)
      |> List.first()

    # 2. Inyectar avatar_url si existe
    user_params = if avatar_url, do: Map.put(user_params, "avatar_url", avatar_url), else: user_params

    case Accounts.update_user(socket.assigns.current_user, user_params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(current_user: user, show_profile: false)
         |> put_flash(:info, "Profile updated successfully!")}

      {:error, changeset} ->
        {:noreply, assign(socket, profile_form: to_form(changeset))}
    end
  end


  def handle_info({:message_created, message}, socket) do
    {:noreply, stream_insert(socket, :messages, message)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex h-screen bg-[#313338] text-[#dbdee1] font-sans overflow-hidden relative">
      <!-- Sidebar Servidores -->
      <div class="w-[72px] bg-[#1e1f22] flex flex-col items-center py-3 space-y-2 flex-shrink-0">
        <div class="w-12 h-12 bg-[#5865f2] rounded-[16px] flex items-center justify-center text-white">
          <svg class="w-7 h-7" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 14.5v-9l6 4.5-6 4.5z"/></svg>
        </div>
        <div class="w-8 h-[2px] bg-[#35363c] rounded-full mx-4"></div>
        <div class="mt-auto mb-4 space-y-4 flex flex-col items-center">
           <button phx-click="toggle_profile" class="w-12 h-12 bg-[#313338] rounded-[24px] hover:rounded-[16px] transition-all duration-200 flex items-center justify-center text-[#23a559] hover:bg-[#23a559] hover:text-white cursor-pointer group shadow-none outline-none">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" /></svg>
           </button>
           
           <.link href={~p"/logout"} method="delete" class="w-12 h-12 bg-[#313338] rounded-[24px] hover:rounded-[16px] transition-all duration-200 flex items-center justify-center text-[#f23f42] hover:bg-[#f23f42] hover:text-white cursor-pointer shadow-none outline-none">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" /></svg>
           </.link>
        </div>
      </div>

      <!-- Sidebar Canales -->
      <div class="w-60 bg-[#2b2d31] flex flex-col flex-shrink-0 hidden md:flex">
        <div class="h-12 px-4 border-b border-[#1f2124] flex items-center shadow-sm">
          <h1 class="font-bold text-white truncate text-sm uppercase">Phoenix Chat</h1>
        </div>
        <div class="flex-1 overflow-y-auto py-3 px-2">
          <div class="flex items-center gap-2 p-2 rounded bg-[#3f4147] text-white">
            <span class="text-[#949ba4] text-xl">#</span>
            <span class="font-medium">general</span>
          </div>
        </div>
        <!-- Footer Perfil -->
        <div class="bg-[#232428] p-2 flex items-center gap-2 cursor-pointer hover:bg-[#35373c] transition-colors" phx-click="toggle_profile">
           <div class="w-8 h-8 rounded-full bg-[#5865f2] overflow-hidden">
             <%= if @current_user.avatar_url do %>
                <img src={@current_user.avatar_url} class="w-full h-full object-cover" />
             <% else %>
                <div class="w-full h-full flex items-center justify-center text-xs font-bold text-white">
                  <%= String.at(@current_user.username, 0) |> String.upcase() %>
                </div>
             <% end %>
           </div>
           <div class="flex-1 min-w-0">
             <div class="text-xs font-bold text-white truncate"><%= @current_user.username %></div>
             <div class="text-[10px] text-[#b5bac1] truncate font-medium">Online</div>
           </div>
        </div>
      </div>

      <!-- Chat -->
      <div class="flex flex-col flex-1 min-w-0">
        <div class="h-12 px-4 border-b border-[#1f2124] flex items-center bg-[#313338] shadow-sm flex-shrink-0">
           <span class="text-[#949ba4] text-2xl mr-2">#</span>
           <span class="font-bold text-white mr-4">general</span>
        </div>

        <div id="messages" phx-update="stream" phx-hook="ScrollDown" class="flex-1 overflow-y-auto p-4 space-y-1">
          <div :for={{dom_id, message} <- @streams.messages} id={dom_id} class="flex items-start gap-4 hover:bg-[#2e3035] -mx-4 px-4 py-[2px] group">
              <div class="w-10 h-10 rounded-full bg-[#5865f2] overflow-hidden mt-1 flex-shrink-0">
                <%= if message.avatar_url do %>
                   <img src={message.avatar_url} class="w-full h-full object-cover" />
                <% else %>
                   <div class="w-full h-full flex items-center justify-center text-white font-bold">
                     <%= String.at(message.username || "?", 0) |> String.upcase() %>
                   </div>
                <% end %>
              </div>
              <div class="flex-1 min-w-0">
                <div class="flex items-baseline gap-2">
                  <span class="font-bold text-white hover:underline cursor-pointer"><%= message.username %></span>
                  <span class="text-[10px] text-[#949ba4] font-medium"><%= Calendar.strftime(message.inserted_at, "%H:%M") %></span>
                </div>
                <div class="text-[#dbdee1] text-[15px] break-words"><%= message.content %></div>
              </div>
          </div>
        </div>

        <div class="px-4 pb-6 pt-2 bg-[#313338]">
          <div class="bg-[#383a40] rounded-lg p-3">
            <.form for={@form} phx-submit="send_message" class="flex items-center gap-3">
              <input type="text" name="message[content]" placeholder={"Message #general"} class="bg-transparent border-none focus:ring-0 p-0 flex-1 text-white placeholder-[#949ba4] shadow-none outline-none" autocomplete="off" />
              <button type="submit" class="text-[#b5bac1] hover:text-white transition-colors">
                 <svg class="w-6 h-6 rotate-90" fill="currentColor" viewBox="0 0 24 24"><path d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z"></path></svg>
              </button>
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
              <div class="absolute -bottom-10 left-4 p-1 bg-[#2b2d31] rounded-full group cursor-pointer relative overflow-hidden">
                <div class="w-20 h-20 rounded-full bg-[#5865f2] border-4 border-[#2b2d31] flex items-center justify-center overflow-hidden">
                   <%= if @current_user.avatar_url do %>
                      <img src={@current_user.avatar_url} class="w-full h-full object-cover" />
                   <% else %>
                      <span class="text-3xl font-bold text-white"><%= String.at(@current_user.username, 0) |> String.upcase() %></span>
                   <% end %>
                </div>
              </div>
            </div>

            <div class="pt-12 p-6">
              <h3 class="text-xl font-bold text-white mb-6 uppercase text-sm tracking-wide">User Settings</h3>
              
              <.form for={@profile_form} phx-change="validate_profile" phx-submit="save_profile" class="space-y-4">
                <div class="bg-[#1e1f22] p-4 rounded-lg space-y-4">
                  <!-- Campo Subida Avatar -->
                  <div>
                    <label class="block text-[11px] font-bold text-[#b5bac1] uppercase mb-2">Change Avatar</label>
                    <.live_file_input upload={@uploads.avatar} class="text-xs text-[#b5bac1] file:bg-[#5865f2] file:text-white file:border-none file:rounded file:px-2 file:py-1 file:mr-2 cursor-pointer" />
                    
                    <%= for entry <- @uploads.avatar.entries do %>
                      <div class="mt-2 text-[10px] text-[#23a559] flex items-center gap-2">
                         <span>Preparing: <%= entry.client_name %></span>
                         <.live_img_preview entry={entry} class="w-8 h-8 rounded-full" />
                      </div>
                    <% end %>
                  </div>

                  <div>
                    <label class="block text-[11px] font-bold text-[#b5bac1] uppercase mb-2">Username</label>
                    <.input field={@profile_form[:username]} class="w-full bg-[#2b2d31] border-none rounded p-2 text-white outline-none" />
                  </div>
                  <div>
                    <label class="block text-[11px] font-bold text-[#b5bac1] uppercase mb-2">Email</label>
                    <.input field={@profile_form[:email]} type="email" class="w-full bg-[#2b2d31] border-none rounded p-2 text-white outline-none" />
                  </div>
                </div>

                <div class="flex justify-end gap-3 pt-4 border-t border-[#35363c]">
                  <button type="button" phx-click="toggle_profile" class="text-sm text-white hover:underline">Cancel</button>
                  <button type="submit" class="bg-[#5865f2] hover:bg-[#4752c4] text-white px-6 py-2 rounded text-sm font-medium">Save Changes</button>
                </div>
              </.form>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
