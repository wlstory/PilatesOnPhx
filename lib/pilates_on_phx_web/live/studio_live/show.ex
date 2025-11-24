defmodule PilatesOnPhxWeb.StudioLive.Show do
  use PilatesOnPhxWeb, :live_view

  on_mount {PilatesOnPhxWeb.UserAuth, :default}

  require Ash.Query

  @impl true
  def mount(_params, _session, socket) do
    actor = socket.assigns[:current_user]

    if is_nil(actor) do
      {:ok,
       socket
       |> put_flash(:error, "You must be logged in to access this page")
       |> redirect(to: "/sign-in")}
    else
      {:ok, socket}
    end
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    actor = socket.assigns.current_user

    case PilatesOnPhx.Studios.Studio
         |> Ash.Query.filter(id == ^id)
         |> Ash.read_one(actor: actor, domain: PilatesOnPhx.Studios) do
      {:ok, studio} when not is_nil(studio) ->
        {:noreply,
         socket
         |> assign(:page_title, studio.name)
         |> assign(:studio, studio)}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Studio not found")
         |> redirect(to: ~p"/studios")}
    end
  end

  @impl true
  def handle_event("activate", _params, socket) do
    actor = socket.assigns.current_user
    studio = socket.assigns.studio

    case studio
         |> Ash.Changeset.for_update(:activate, %{}, actor: actor)
         |> Ash.update(domain: PilatesOnPhx.Studios) do
      {:ok, updated_studio} ->
        {:noreply,
         socket
         |> assign(:studio, updated_studio)
         |> put_flash(:info, "Studio activated successfully")}

      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Failed to activate studio")}
    end
  end

  @impl true
  def handle_event("deactivate", _params, socket) do
    actor = socket.assigns.current_user

    unless user_is_owner_in_any_org?(actor) do
      raise "Unauthorized: Only owners can deactivate studios"
    end

    studio = socket.assigns.studio

    case studio
         |> Ash.Changeset.for_update(:deactivate, %{}, actor: actor)
         |> Ash.update(domain: PilatesOnPhx.Studios) do
      {:ok, updated_studio} ->
        {:noreply,
         socket
         |> assign(:studio, updated_studio)
         |> put_flash(:info, "Studio deactivated successfully")}

      {:error, _error} ->
        {:noreply, put_flash(socket, :error, "Failed to deactivate studio")}
    end
  end

  defp user_is_owner_in_any_org?(user) do
    case Map.get(user, :memberships) do
      memberships when is_list(memberships) ->
        Enum.any?(memberships, fn m -> m.role == :owner end)

      _ ->
        case Ash.load(user, :memberships, domain: PilatesOnPhx.Accounts, authorize?: false) do
          {:ok, loaded_user} ->
            Enum.any?(loaded_user.memberships || [], fn m -> m.role == :owner end)

          _ ->
            false
        end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <div class="flex justify-between items-center mb-6">
        <h1 class="text-3xl font-bold">{@studio.name}</h1>
        <div class="flex gap-2">
          <.link
            :if={user_is_owner_in_any_org?(@current_user)}
            navigate={~p"/studios/#{@studio}/edit"}
            class="btn btn-primary"
          >
            Edit Studio
          </.link>
          <.link navigate={~p"/studios"} class="btn btn-ghost">
            Back to Studios
          </.link>
        </div>
      </div>

      <div class="card bg-base-100 shadow-xl mb-6">
        <div class="card-body">
          <h2 class="card-title">Studio Information</h2>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
            <div>
              <p class="text-sm text-gray-500">Address</p>
              <p class="font-medium">{@studio.address}</p>
            </div>
            <div>
              <p class="text-sm text-gray-500">Timezone</p>
              <p class="font-medium">{@studio.timezone}</p>
            </div>
            <div>
              <p class="text-sm text-gray-500">Max Capacity</p>
              <p class="font-medium">{@studio.max_capacity}</p>
            </div>
            <div>
              <p class="text-sm text-gray-500">Status</p>
              <span class={[
                "badge",
                @studio.active && "badge-success",
                !@studio.active && "badge-error"
              ]}>
                {if @studio.active, do: "Active", else: "Inactive"}
              </span>
            </div>
            <div :if={@studio.settings && @studio.settings["wifi_password"]}>
              <p class="text-sm text-gray-500">WiFi Password</p>
              <p class="font-medium">{@studio.settings["wifi_password"]}</p>
            </div>
            <div :if={@studio.settings && @studio.settings["parking_info"]}>
              <p class="text-sm text-gray-500">Parking Info</p>
              <p class="font-medium">{@studio.settings["parking_info"]}</p>
            </div>
          </div>

          <div :if={user_is_owner_in_any_org?(@current_user)} class="card-actions justify-end mt-4">
            <button
              :if={!@studio.active}
              phx-click="activate"
              data-confirm="Are you sure you want to activate this studio?"
              class="btn btn-success"
            >
              Activate
            </button>
            <button
              :if={@studio.active}
              phx-click="deactivate"
              data-confirm="Are you sure you want to deactivate this studio?"
              class="btn btn-warning"
            >
              Deactivate Studio
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
