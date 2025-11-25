defmodule PilatesOnPhxWeb.UserAuth do
  @moduledoc """
  LiveView authentication hooks for user session management.
  """
  import Phoenix.Component

  def on_mount(:default, _params, session, socket) do
    socket =
      case session["user_token"] do
        nil ->
          assign(socket, :current_user, nil)

        token ->
          case AshAuthentication.Jwt.peek(token) do
            {:ok, %{"sub" => subject}} ->
              # Extract user ID from subject (format: "user?id=<uuid>")
              user_id =
                subject
                |> String.split("id=")
                |> List.last()

              # Load the user with their memberships
              user =
                PilatesOnPhx.Accounts.User
                |> Ash.get!(user_id,
                  domain: PilatesOnPhx.Accounts,
                  authorize?: false,
                  load: [:memberships]
                )

              assign(socket, :current_user, user)

            _ ->
              assign(socket, :current_user, nil)
          end
      end

    {:cont, socket}
  end
end
