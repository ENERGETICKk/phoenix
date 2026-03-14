defmodule ChatMiniWeb.MarkdownLive do
  use ChatMiniWeb, :live_view
  alias ChatMini.Accounts

  def mount(_params, session, socket) do
    user_id = session["user_id"]
    current_user = Accounts.get_user!(user_id)

    # Path to results folder (parent of project)
    results_path = Path.expand("../", File.cwd!())
    files = list_md_files(results_path)

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:results_path, results_path)
     |> assign(:files, files)
     |> assign(:current_file, nil)
     |> assign(:content, "")
     |> assign(:html_content, "")
     |> assign(:show_profile, false)
     |> assign(:profile_form, to_form(Accounts.change_user(current_user)))
     |> allow_upload(:avatar, accept: ~w(.jpg .jpeg .png), max_entries: 1, max_file_size: 10_000_000)}
  end

  def handle_params(%{"filename" => filename}, _uri, socket) do
    path = Path.join(socket.assigns.results_path, filename)
    content = File.read!(path)
    html = render_markdown(content)

    {:noreply,
     socket
     |> assign(:current_file, filename)
     |> assign(:content, content)
     |> assign(:html_content, html)}
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  def handle_event("update_content", %{"content" => content}, socket) do
    {:noreply,
     socket
     |> assign(:content, content)
     |> assign(:html_content, render_markdown(content))}
  end

  def handle_event("save_content", _, socket) do
    if socket.assigns.current_file do
      path = Path.join(socket.assigns.results_path, socket.assigns.current_file)
      File.write!(path, socket.assigns.content)
      {:noreply, put_flash(socket, :info, "File saved successfully!")}
    else
      {:noreply, socket}
    end
  end

  # Profile logic same as ChatLive
  def handle_event("toggle_profile", _, socket), do: {:noreply, assign(socket, show_profile: !socket.assigns.show_profile)}
  def handle_event("validate_profile", %{"user" => p}, socket) do
    cs = socket.assigns.current_user |> Accounts.change_user(p) |> Map.put(:action, :validate)
    {:noreply, assign(socket, profile_form: to_form(cs))}
  end
  def handle_event("save_profile", %{"user" => p}, socket) do
    avatar_url = consume_uploaded_entries(socket, :avatar, fn %{path: path}, entry ->
      ext = Path.extname(entry.client_name)
      file_name = "#{socket.assigns.current_user.id}_avatar#{ext}"
      dest = Path.join(["priv", "static", "uploads", file_name])
      File.cp!(path, dest)
      {:ok, "/uploads/#{file_name}"}
    end) |> List.first()
    p = if avatar_url, do: Map.put(p, "avatar_url", avatar_url), else: p
    case Accounts.update_user(socket.assigns.current_user, p) do
      {:ok, user} -> {:noreply, socket |> assign(current_user: user, show_profile: false) |> put_flash(:info, "Profile updated!")}
      {:error, cs} -> {:noreply, assign(socket, profile_form: to_form(cs))}
    end
  end

  defp list_md_files(path) do
    File.ls!(path)
    |> Enum.filter(&String.ends_with?(&1, ".md"))
    |> Enum.sort()
  end

  defp render_markdown(content) do
    content
    |> Earmark.as_html!([])
    |> Phoenix.HTML.raw()
  end

  def render(assigns) do
    ~H"""
    <style>
      .markdown-content h1 { font-size: 2.25rem; font-weight: 800; border-bottom: 1px solid #e5e7eb; padding-bottom: 0.5rem; margin-bottom: 1.5rem; margin-top: 2rem; color: #111827; }
      .markdown-content h2 { font-size: 1.5rem; font-weight: 700; border-bottom: 1px solid #f3f4f6; padding-bottom: 0.3rem; margin-bottom: 1rem; margin-top: 1.5rem; color: #1f2937; }
      .markdown-content h3 { font-size: 1.25rem; font-weight: 600; margin-bottom: 0.75rem; margin-top: 1.25rem; color: #374151; }
      .markdown-content p { margin-bottom: 1rem; line-height: 1.6; color: #4b5563; }
      .markdown-content ul { list-style-type: disc; padding-left: 1.5rem; margin-bottom: 1rem; }
      .markdown-content ol { list-style-type: decimal; padding-left: 1.5rem; margin-bottom: 1rem; }
      .markdown-content li { margin-bottom: 0.25rem; color: #4b5563; }
      .markdown-content blockquote { border-left: 4px solid #e5e7eb; padding-left: 1rem; font-style: italic; color: #6b7280; margin-bottom: 1rem; }
      .markdown-content hr { margin: 2rem 0; border: 0; border-top: 1px solid #e5e7eb; }
      .markdown-content a { color: #5865f2; text-decoration: underline; }
      .markdown-content pre { background-color: #f3f4f6; padding: 1rem; border-radius: 0.5rem; overflow-x: auto; margin-bottom: 1rem; border: 1px solid #e5e7eb; color: #1f2937; font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace; }
      .markdown-content code { background-color: #f3f4f6; padding: 0.2rem 0.4rem; border-radius: 0.25rem; font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace; color: #ff1900; font-size: 0.875em; }
      .markdown-content pre code { background-color: transparent; padding: 0; color: inherit; font-size: inherit; }
    </style>
    <div class="flex h-screen bg-[#313338] text-[#dbdee1] font-sans overflow-hidden relative">
      <!-- 1. Sidebar Servidores -->
      <div class="w-[72px] bg-[#1e1f22] flex flex-col items-center py-3 space-y-2 flex-shrink-0 border-r border-black/20">
        <!-- Chat Server Icon -->
        <.link navigate={~p"/chat"} class="w-12 h-12 bg-[#313338] rounded-[24px] hover:rounded-[16px] transition-all duration-200 flex items-center justify-center text-[#dbdee1] hover:bg-[#5865f2] hover:text-white cursor-pointer group relative">
          <svg class="w-7 h-7" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 14.5v-9l6 4.5-6 4.5z"/></svg>
        </.link>

        <!-- Markdown Triangle Icon -->
        <.link navigate={~p"/docs"} class="w-12 h-12 bg-[#5865f2] rounded-[16px] flex items-center justify-center text-white cursor-pointer relative group">
           <svg class="w-7 h-7" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2L2 22h20L12 2z"/></svg>
           <div class="absolute left-[72px] bg-black text-white text-xs px-2 py-1 rounded opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap z-50">Docs Editor</div>
        </.link>

        <div class="w-8 h-[2px] bg-[#35363c] rounded-full mx-4"></div>
        <div class="mt-auto mb-4 space-y-4 flex flex-col items-center">
           <button phx-click="toggle_profile" class="w-12 h-12 bg-[#313338] rounded-[24px] hover:rounded-[16px] transition-all duration-200 flex items-center justify-center text-[#23a559] hover:bg-[#23a559] hover:text-white outline-none"><svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" /></svg></button>
           <.link href={~p"/logout"} method="delete" class="w-12 h-12 bg-[#313338] rounded-[24px] hover:rounded-[16px] transition-all duration-200 flex items-center justify-center text-[#f23f42] hover:bg-[#f23f42] hover:text-white outline-none"><svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" /></svg></.link>
        </div>
      </div>

      <!-- 2. Sidebar Archivos -->
      <div class="w-60 bg-[#2b2d31] flex flex-col flex-shrink-0 hidden md:flex border-r border-black/20">
        <div class="h-12 px-4 border-b border-[#1f2124] flex items-center shadow-sm">
          <h1 class="font-bold text-white truncate text-sm tracking-wider uppercase">MARKDOWN DOCS</h1>
        </div>
        <div class="flex-1 p-2 space-y-[2px] overflow-y-auto bg-[#2b2d31]">
          <%= for file <- @files do %>
            <.link patch={~p"/docs/#{file}"} class={"flex items-center gap-2 p-2 rounded cursor-pointer group #{if @current_file == file, do: "bg-[#3f4147] text-white", else: "text-[#949ba4] hover:bg-[#35373c] hover:text-[#dbdee1]"}"}>
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" /></svg>
              <span class="font-medium text-xs truncate"><%= file %></span>
            </.link>
          <% end %>
        </div>
        <div class="bg-[#232428] p-2 flex items-center gap-2 cursor-pointer" phx-click="toggle_profile">
           <div class="w-8 h-8 rounded-full bg-[#5865f2] overflow-hidden">
             <%= if @current_user.avatar_url do %><img src={@current_user.avatar_url} class="w-full h-full object-cover" /><% else %>
             <div class="w-full h-full flex items-center justify-center text-xs font-bold text-white"><%= String.at(@current_user.username, 0) |> String.upcase() %></div><% end %>
           </div>
           <div class="flex-1 min-w-0"><div class="text-xs font-bold text-white truncate"><%= @current_user.username %></div><div class="text-[10px] text-[#b5bac1]">Markdown Mode</div></div>
        </div>
      </div>

      <!-- 3. Editor & Preview Area -->
      <div class="flex flex-col flex-1 min-w-0 bg-[#313338]">
        <!-- Header -->
        <div class="h-12 px-4 border-b border-[#1f2124] flex items-center justify-between bg-[#313338] shadow-sm flex-shrink-0">
           <div class="flex items-center gap-2">
             <span class="text-[#949ba4] text-xl font-bold">📄</span>
             <span class="font-bold text-white"><%= @current_file || "Select a file to preview" %></span>
           </div>
           <%= if @current_file do %>
             <button phx-click="save_content" class="bg-[#23a559] hover:bg-[#1a7a42] text-white text-xs px-3 py-1 rounded font-bold transition-colors">
               Save Changes
             </button>
           <% end %>
        </div>

        <div class="flex-1 flex overflow-hidden">
          <%= if @current_file do %>
            <!-- Editor (Left) -->
            <div class="w-1/2 h-full border-r border-[#1f2124] p-4">
              <textarea
                phx-keyup="update_content"
                class="w-full h-full bg-transparent border-none text-[#dbdee1] text-sm font-mono focus:ring-0 resize-none outline-none p-0"
                spellcheck="false"
              ><%= @content %></textarea>
            </div>
            <!-- Preview (Right) -->
            <div class="w-1/2 h-full overflow-y-auto p-10 bg-white text-[#2e3338] markdown-content">
              <%= @html_content %>
            </div>

          <% else %>
            <div class="flex-1 flex flex-col items-center justify-center opacity-20 pointer-events-none">
              <svg class="w-32 h-32 mb-4" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2L2 22h20L12 2z"/></svg>
              <p class="text-2xl font-bold">Select a markdown file to begin editing</p>
            </div>
          <% end %>
        </div>
      </div>

      <!-- MODAL PERFIL (Reused) -->
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
                  <div><label class="block text-[11px] font-bold text-[#b5bac1] uppercase mb-2">Avatar</label><.live_file_input upload={@uploads.avatar} class="text-xs text-[#b5bac1]" /></div>
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
