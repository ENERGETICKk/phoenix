defmodule ChatMiniWeb.AuthLive do
  use ChatMiniWeb, :live_view
  alias ChatMini.Accounts
  alias ChatMini.Accounts.User

  def mount(_params, session, socket) do
    if Map.has_key?(session, "user_id") do
       {:ok, redirect(socket, to: ~p"/chat")}
    else
      {:ok,
       socket
       |> assign(:trigger_submit, false)
       |> assign(:form_login, to_form(%{"email" => "", "password" => ""}))
       |> assign(:form_register, to_form(Accounts.change_user(%User{})))}
    end
  end

  def handle_event("register", %{"user" => user_params}, socket) do
    case Accounts.create_user(user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "Account created! Now you can Sign In.")
         |> assign(:form_register, to_form(Accounts.change_user(%User{})))}

      {:error, changeset} ->
        {:noreply, assign(socket, :form_register, to_form(changeset))}
    end
  end

  def handle_event("login", params, socket) do
    {:noreply, assign(socket, trigger_submit: true, form_login: to_form(params))}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-[#313338] flex items-center justify-center p-6 font-sans">
      <div class="max-w-5xl w-full grid md:grid-cols-2 gap-8">

        <!-- Login Section -->
        <div class="bg-[#2b2d31] p-8 rounded-lg shadow-xl border border-[#1e1f22]">
          <h2 class="text-2xl font-bold text-white mb-2 text-center">Hola de Vuelta Adam!</h2>
          <p class="text-[#b5bac1] text-center mb-8 text-sm">Este es mi chat personal para gestionar mis ideas</p>

          <.form for={@form_login} action={~p"/login"} phx-submit="login" phx-trigger-action={@trigger_submit} class="space-y-5">
            <div>
              <label class="block text-[11px] font-bold text-[#b5bac1] uppercase mb-2">Email</label>
              <input type="email" name="email" required value={@form_login[:email].value}
                class="w-full bg-[#1e1f22] border-none rounded p-3 text-white focus:ring-1 focus:ring-[#5865f2] outline-none" />
            </div>
            <div>
              <label class="block text-[11px] font-bold text-[#b5bac1] uppercase mb-2">Password</label>
              <input type="password" name="password" required value={@form_login[:password].value}
                class="w-full bg-[#1e1f22] border-none rounded p-3 text-white focus:ring-1 focus:ring-[#5865f2] outline-none" />
            </div>
            <button type="submit" class="w-full bg-[#5865f2] hover:bg-[#4752c4] text-white font-bold py-3 rounded transition-colors mt-4">
              Log In
            </button>
          </.form>
        </div>

        <!-- Register Section -->
        <div class="bg-[#2b2d31] p-8 rounded-lg shadow-xl border border-[#1e1f22]">
          <h2 class="text-2xl font-bold text-white mb-2 text-center">Crea una Cuenta</h2>
          <p class="text-[#b5bac1] text-center mb-8 text-sm">Usa el chat que he creado!</p>

          <.form for={@form_register} phx-submit="register" class="space-y-4">
            <div>
              <label class="block text-[11px] font-bold text-[#b5bac1] uppercase mb-2">Username</label>
              <.input field={@form_register[:username]} placeholder="How should we call you?" required
                class="w-full bg-[#1e1f22] border-none rounded p-3 text-white focus:ring-1 focus:ring-[#5865f2] outline-none" />
            </div>
            <div>
              <label class="block text-[11px] font-bold text-[#b5bac1] uppercase mb-2">Email</label>
              <.input field={@form_register[:email]} type="email" placeholder="email@example.com" required
                class="w-full bg-[#1e1f22] border-none rounded p-3 text-white focus:ring-1 focus:ring-[#5865f2] outline-none" />
            </div>
            <div>
              <label class="block text-[11px] font-bold text-[#b5bac1] uppercase mb-2">Password</label>
              <.input field={@form_register[:password]} type="password" placeholder="Min. 6 characters" required
                class="w-full bg-[#1e1f22] border-none rounded p-3 text-white focus:ring-1 focus:ring-[#5865f2] outline-none" />
            </div>
            <button type="submit" class="w-full bg-[#23a559] hover:bg-[#1a7a42] text-white font-bold py-3 rounded transition-colors mt-4">
              Continue
            </button>
          </.form>
        </div>

      </div>
    </div>
    """
  end
end
