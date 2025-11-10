defmodule PilatesOnPhxWeb.PageController do
  use PilatesOnPhxWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
