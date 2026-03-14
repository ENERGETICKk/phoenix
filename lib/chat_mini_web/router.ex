defmodule ChatMiniWeb.Router do
  use ChatMiniWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ChatMiniWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  defp fetch_current_user(conn, _opts) do
    user_id = get_session(conn, :user_id)
    user = user_id && ChatMini.Accounts.get_user!(user_id)
    assign(conn, :current_user, user)
  end

  defp require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> redirect(to: ~p"/")
      |> halt()
    end
  end

  scope "/", ChatMiniWeb do
    pipe_through :browser

    live "/", AuthLive, :index
    post "/login", SessionController, :create
    delete "/logout", SessionController, :delete
  end

  scope "/", ChatMiniWeb do
    pipe_through [:browser, :require_authenticated_user]

    live "/chat", ChatLive, :index
  end

  if Application.compile_env(:chat_mini, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ChatMiniWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
