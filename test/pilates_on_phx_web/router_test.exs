defmodule PilatesOnPhxWeb.RouterTest do
  use PilatesOnPhxWeb.ConnCase, async: true

  alias PilatesOnPhxWeb.Router

  describe "router configuration" do
    test "defines expected pipelines" do
      # Verify browser pipeline exists and is callable
      assert function_exported?(Router, :__pipelines__, 0)
      pipelines = Router.__pipelines__()

      assert :browser in pipelines
      assert :api in pipelines
    end
  end

  describe "routes" do
    test "GET / is defined and points to PageController" do
      conn = build_conn()
      conn = get(conn, "/")

      assert conn.status == 200
      assert conn.private[:phoenix_controller] == PilatesOnPhxWeb.PageController
      assert conn.private[:phoenix_action] == :home
    end

    test "root path helper works" do
      assert ~p"/" == "/"
    end

    test "non-existent routes return 404" do
      conn = build_conn()

      assert_error_sent 404, fn ->
        get(conn, "/nonexistent-route")
      end
    end
  end

  describe "router module" do
    test "uses PilatesOnPhxWeb router" do
      assert Code.ensure_loaded?(PilatesOnPhxWeb.Router)
    end

    test "implements Phoenix.Router behavior" do
      assert function_exported?(Router, :__routes__, 0)
      assert is_list(Router.__routes__())
    end
  end
end
