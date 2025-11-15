defmodule PilatesOnPhxWeb.CoreComponentsTest do
  use PilatesOnPhxWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import PilatesOnPhxWeb.CoreComponents

  # Helper to render component and convert to string
  defp render_component(component_call) do
    component_call
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  describe "flash/1" do
    test "renders info flash message" do
      assigns = %{
        flash: %{"info" => "Operation successful"},
        kind: :info,
        id: "flash-info"
      }

      html =
        render_component(~H"""
        <.flash kind={:info} flash={@flash} id="flash-info" />
        """)

      assert html =~ "Operation successful"
    end

    test "renders error flash message" do
      assigns = %{
        flash: %{"error" => "Something went wrong"},
        kind: :error,
        id: "flash-error"
      }

      html =
        render_component(~H"""
        <.flash kind={:error} flash={@flash} id="flash-error" />
        """)

      assert html =~ "Something went wrong"
    end

    test "renders flash with custom title" do
      assigns = %{
        flash: %{},
        kind: :info,
        title: "Custom Title",
        id: "flash-custom"
      }

      html =
        render_component(~H"""
        <.flash kind={:info} flash={@flash} title="Custom Title" id="flash-custom" />
        """)

      assert html =~ "Custom Title"
    end
  end

  describe "button/1" do
    test "renders a button with default attributes" do
      assigns = %{}

      html =
        render_component(~H"""
        <.button>Click me</.button>
        """)

      assert html =~ "Click me"
      assert html =~ "<button"
    end

    test "renders button with custom type" do
      assigns = %{}

      html =
        render_component(~H"""
        <.button type="submit">Submit</.button>
        """)

      assert html =~ "type=\"submit\""
      assert html =~ "Submit"
    end
  end

  describe "input/1" do
    setup do
      # Create a simple form for testing
      form =
        Phoenix.Component.to_form(
          %{"email" => "test@example.com", "name" => "John"},
          as: :user
        )

      %{form: form}
    end

    test "renders text input", %{form: form} do
      assigns = %{form: form}

      html =
        render_component(~H"""
        <.input field={@form[:email]} type="text" />
        """)

      assert html =~ "type=\"text\""
      assert html =~ "user[email]"
    end

    test "renders checkbox input", %{form: form} do
      assigns = %{form: form}

      html =
        render_component(~H"""
        <.input field={@form[:accept]} type="checkbox" label="Accept terms" />
        """)

      assert html =~ "type=\"checkbox\""
      assert html =~ "Accept terms"
    end

    test "renders select input", %{form: form} do
      assigns = %{form: form}

      html =
        render_component(~H"""
        <.input field={@form[:role]} type="select" options={[{"Admin", "admin"}, {"User", "user"}]} />
        """)

      assert html =~ "<select"
      assert html =~ "Admin"
      assert html =~ "User"
    end

    test "renders textarea input", %{form: form} do
      assigns = %{form: form}

      html =
        render_component(~H"""
        <.input field={@form[:bio]} type="textarea" />
        """)

      assert html =~ "<textarea"
    end
  end

  describe "header/1" do
    test "renders header with title" do
      assigns = %{}

      html =
        render_component(~H"""
        <.header>
          Page Title
        </.header>
        """)

      assert html =~ "Page Title"
    end

    test "renders header with subtitle" do
      assigns = %{}

      html =
        render_component(~H"""
        <.header>
          Main Title
          <:subtitle>Subtitle text</:subtitle>
        </.header>
        """)

      assert html =~ "Main Title"
      assert html =~ "Subtitle text"
    end
  end

  describe "table/1" do
    setup do
      rows = [
        %{id: 1, name: "Alice", email: "alice@example.com"},
        %{id: 2, name: "Bob", email: "bob@example.com"}
      ]

      %{rows: rows}
    end

    test "renders table with rows", %{rows: rows} do
      assigns = %{rows: rows}

      html =
        render_component(~H"""
        <.table id="users" rows={@rows}>
          <:col :let={user} label="Name">{user.name}</:col>
          <:col :let={user} label="Email">{user.email}</:col>
        </.table>
        """)

      assert html =~ "<table"
      assert html =~ "Alice"
      assert html =~ "Bob"
      assert html =~ "alice@example.com"
    end
  end

  describe "list/1" do
    test "renders list with items" do
      assigns = %{}

      html =
        render_component(~H"""
        <.list>
          <:item title="Name">John Doe</:item>
          <:item title="Email">john@example.com</:item>
        </.list>
        """)

      assert html =~ "Name"
      assert html =~ "John Doe"
      assert html =~ "Email"
      assert html =~ "john@example.com"
    end
  end

  describe "icon/1" do
    test "renders heroicon" do
      assigns = %{}

      html =
        render_component(~H"""
        <.icon name="hero-user" />
        """)

      assert html =~ "<span"
      assert html =~ "hero-user"
    end

    test "renders icon with custom class" do
      assigns = %{}

      html =
        render_component(~H"""
        <.icon name="hero-home" class="custom-icon" />
        """)

      assert html =~ "custom-icon"
    end
  end

  describe "show/2 and hide/2" do
    test "show creates JS command for showing element" do
      result = show("#my-element")

      assert %Phoenix.LiveView.JS{} = result
    end

    test "hide creates JS command for hiding element" do
      result = hide("#my-element")

      assert %Phoenix.LiveView.JS{} = result
    end

    test "show and hide can be chained" do
      result =
        %Phoenix.LiveView.JS{}
        |> show("#element1")
        |> hide("#element2")

      assert %Phoenix.LiveView.JS{} = result
    end
  end

  describe "translate_error/1" do
    test "translates error message without opts" do
      result = translate_error({"is invalid", []})
      assert result == "is invalid"
    end

    test "translates error message with count" do
      result = translate_error({"should be at least %{count} character(s)", [count: 5]})
      assert result =~ "5"
    end
  end

  describe "translate_errors/2" do
    test "translates list of errors" do
      errors = [
        {"is invalid", []},
        {"should be at least %{count} character(s)", [count: 3]}
      ]

      result = translate_errors(errors, :email)
      assert is_list(result)
      assert length(result) == 2
    end

    test "handles empty errors list" do
      result = translate_errors([], :email)
      assert result == []
    end
  end
end
