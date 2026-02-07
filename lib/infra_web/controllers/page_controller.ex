defmodule InfraWeb.PageController do
  use InfraWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
