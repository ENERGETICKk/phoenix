defmodule ContadorWeb.PageController do
  use ContadorWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
