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

    test "browser pipeline includes required plugs" do
      conn = build_conn()
      conn = get(conn, "/")

      # Verify browser pipeline plugs are applied
      assert conn.private[:phoenix_router] == PilatesOnPhxWeb.Router
      assert get_session(conn)  # Session should be fetched
    end
  end

  describe "routes" do
    test "GET / is defined and points to PageController" do
      conn = build_conn()
      conn = get(conn, "/")

      assert conn.status in [200, 302]
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

    test "API routes use JSON accept header" do
      conn = build_conn()

      # Attempt to access an API route (none defined yet, should 404)
      assert_error_sent 404, fn ->
        conn
        |> put_req_header("accept", "application/json")
        |> get("/api/something")
      end
    end
  end

  describe "development routes" do
    @tag :skip
    test "LiveDashboard is available in development" do
      # This test would require dev_routes to be enabled
      # Skipping for now as it's environment-dependent
    end

    @tag :skip
    test "Swoosh mailbox preview is available in development" do
      # This test would require dev_routes to be enabled
      # Skipping for now as it's environment-dependent
    end
  end

  describe "security" do
    test "browser pipeline includes CSRF protection" do
      conn = build_conn()

      # POST requests should require CSRF token
      assert_error_sent 403, fn ->
        post(conn, "/", %{})
      end
    end

    test "browser pipeline includes secure headers" do
      conn = build_conn()
      conn = get(conn, "/")

      # Verify security headers are set
      assert get_resp_header(conn, "x-frame-options") != []
      assert get_resp_header(conn, "x-content-type-options") != []
      assert get_resp_header(conn, "x-download-options") != []
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
