defmodule PilatesOnPhxWeb.LayoutsTest do
  use PilatesOnPhxWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PilatesOnPhxWeb.Layouts

  describe "app/1" do
    test "renders app layout with content" do
      assigns = %{flash: %{}, current_scope: nil}

      html =
        rendered_to_string(~H"""
        <.app flash={@flash}>
          <h1>Test Content</h1>
        </.app>
        """)

      assert html =~ "Test Content"
      assert html =~ "<header"
      assert html =~ "<main"
    end

    test "includes navigation links" do
      assigns = %{flash: %{}, current_scope: nil}

      html =
        rendered_to_string(~H"""
        <.app flash={@flash}>
          Content
        </.app>
        """)

      assert html =~ "phoenixframework.org"
      assert html =~ "GitHub"
      assert html =~ "Get Started"
    end

    test "includes logo" do
      assigns = %{flash: %{}, current_scope: nil}

      html =
        rendered_to_string(~H"""
        <.app flash={@flash}>
          Content
        </.app>
        """)

      assert html =~ "/images/logo.svg"
    end

    test "includes theme toggle" do
      assigns = %{flash: %{}, current_scope: nil}

      html =
        rendered_to_string(~H"""
        <.app flash={@flash}>
          Content
        </.app>
        """)

      # Theme toggle should be rendered
      assert html =~ "hero-computer-desktop-micro" or
               html =~ "hero-sun-micro" or
               html =~ "hero-moon-micro"
    end

    test "renders flash messages" do
      assigns = %{flash: %{"info" => "Success message"}, current_scope: nil}

      html =
        rendered_to_string(~H"""
        <.app flash={@flash}>
          Content
        </.app>
        """)

      assert html =~ "Success message"
    end
  end

  describe "flash_group/1" do
    test "renders flash group container" do
      assigns = %{flash: %{}}

      html =
        rendered_to_string(~H"""
        <.flash_group flash={@flash} />
        """)

      assert html =~ "flash-group"
      assert html =~ "aria-live=\"polite\""
    end

    test "renders custom id" do
      assigns = %{flash: %{}}

      html =
        rendered_to_string(~H"""
        <.flash_group flash={@flash} id="custom-flash" />
        """)

      assert html =~ "custom-flash"
    end

    test "includes client error flash" do
      assigns = %{flash: %{}}

      html =
        rendered_to_string(~H"""
        <.flash_group flash={@flash} />
        """)

      assert html =~ "client-error"
      assert html =~ "We can't find the internet"
    end

    test "includes server error flash" do
      assigns = %{flash: %{}}

      html =
        rendered_to_string(~H"""
        <.flash_group flash={@flash} />
        """)

      assert html =~ "server-error"
      assert html =~ "Something went wrong!"
    end

    test "renders info flash when present" do
      assigns = %{flash: %{"info" => "Operation completed"}}

      html =
        rendered_to_string(~H"""
        <.flash_group flash={@flash} />
        """)

      assert html =~ "Operation completed"
    end

    test "renders error flash when present" do
      assigns = %{flash: %{"error" => "Operation failed"}}

      html =
        rendered_to_string(~H"""
        <.flash_group flash={@flash} />
        """)

      assert html =~ "Operation failed"
    end
  end

  describe "theme_toggle/1" do
    test "renders theme toggle component" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.theme_toggle />
        """)

      # Should have buttons for system, light, and dark themes
      assert html =~ "data-phx-theme=\"system\""
      assert html =~ "data-phx-theme=\"light\""
      assert html =~ "data-phx-theme=\"dark\""
    end

    test "includes theme icons" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.theme_toggle />
        """)

      assert html =~ "hero-computer-desktop-micro"
      assert html =~ "hero-sun-micro"
      assert html =~ "hero-moon-micro"
    end

    test "includes theme switching JS events" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.theme_toggle />
        """)

      assert html =~ "phx:set-theme"
    end
  end
end
