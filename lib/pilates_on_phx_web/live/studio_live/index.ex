defmodule PilatesOnPhxWeb.StudioLive.Index do
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
      # All authenticated users can view studios list (filtered by their organizations)
      # Owner-only actions are protected in apply_action
      {:ok, socket}
    end
  end

  defp user_is_owner_in_any_org?(user) do
    # Check if user has loaded memberships
    case Map.get(user, :memberships) do
      memberships when is_list(memberships) ->
        Enum.any?(memberships, fn m -> m.role == :owner end)

      _ ->
        # Memberships not loaded, try to load them
        case Ash.load(user, :memberships, domain: PilatesOnPhx.Accounts, authorize?: false) do
          {:ok, loaded_user} ->
            Enum.any?(loaded_user.memberships || [], fn m -> m.role == :owner end)

          _ ->
            false
        end
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    actor = socket.assigns.current_user

    studios =
      PilatesOnPhx.Studios.Studio
      |> Ash.Query.sort(name: :asc)
      |> Ash.read!(actor: actor, domain: PilatesOnPhx.Studios)

    case PilatesOnPhx.Studios.Studio
         |> Ash.Query.filter(id == ^id)
         |> Ash.read_one(actor: actor, domain: PilatesOnPhx.Studios) do
      {:ok, studio} when not is_nil(studio) ->
        socket
        |> assign(:page_title, "Edit Studio")
        |> assign(:studio, studio)
        |> assign(:studios, studios)

      _ ->
        socket
        |> put_flash(:error, "Studio not found")
        |> redirect(to: ~p"/studios")
    end
  end

  defp apply_action(socket, :new, _params) do
    actor = socket.assigns.current_user

    # Only owners can create studios
    if user_is_owner_in_any_org?(actor) do
      studios =
        PilatesOnPhx.Studios.Studio
        |> Ash.Query.sort(name: :asc)
        |> Ash.read!(actor: actor, domain: PilatesOnPhx.Studios)

      socket
      |> assign(:page_title, "New Studio")
      |> assign(:studio, nil)
      |> assign(:studios, studios)
    else
      socket
      |> put_flash(:error, "You must be an owner to create studios")
      |> redirect(to: ~p"/")
    end
  end

  defp apply_action(socket, :index, _params) do
    actor = socket.assigns.current_user

    studios =
      PilatesOnPhx.Studios.Studio
      |> Ash.Query.sort(name: :asc)
      |> Ash.read!(actor: actor, domain: PilatesOnPhx.Studios)

    socket
    |> assign(:page_title, "Studios")
    |> assign(:studio, nil)
    |> assign(:studios, studios)
  end

  @impl true
  def handle_info({PilatesOnPhxWeb.StudioLive.FormComponent, {:saved, studio}}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Studio #{studio.name} saved successfully")
     |> redirect(to: ~p"/studios/#{studio}")}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    actor = socket.assigns.current_user

    case PilatesOnPhx.Studios.Studio
         |> Ash.Query.filter(id == ^id)
         |> Ash.read_one(actor: actor, domain: PilatesOnPhx.Studios) do
      {:ok, studio} when not is_nil(studio) ->
        case Ash.destroy(studio, actor: actor, domain: PilatesOnPhx.Studios) do
          :ok ->
            studios =
              PilatesOnPhx.Studios.Studio
              |> Ash.Query.sort(name: :asc)
              |> Ash.read!(actor: actor, domain: PilatesOnPhx.Studios)

            {:noreply,
             socket
             |> assign(:studios, studios)
             |> put_flash(:info, "Studio deleted successfully")}

          {:error, _error} ->
            {:noreply, put_flash(socket, :error, "Failed to delete studio")}
        end

      _ ->
        {:noreply, put_flash(socket, :error, "Studio not found")}
    end
  end

  @impl true
  def handle_event("deactivate", %{"id" => id}, socket) do
    actor = socket.assigns.current_user

    case PilatesOnPhx.Studios.Studio
         |> Ash.Query.filter(id == ^id)
         |> Ash.read_one(actor: actor, domain: PilatesOnPhx.Studios) do
      {:ok, studio} when not is_nil(studio) ->
        case studio
             |> Ash.Changeset.for_update(:deactivate, %{}, actor: actor)
             |> Ash.update(domain: PilatesOnPhx.Studios) do
          {:ok, _updated_studio} ->
            studios =
              PilatesOnPhx.Studios.Studio
              |> Ash.Query.sort(name: :asc)
              |> Ash.read!(actor: actor, domain: PilatesOnPhx.Studios)

            {:noreply,
             socket
             |> assign(:studios, studios)
             |> put_flash(:info, "Studio deactivated successfully")}

          {:error, _error} ->
            {:noreply, put_flash(socket, :error, "Failed to deactivate studio")}
        end

      _ ->
        {:noreply, put_flash(socket, :error, "Studio not found")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <div class="flex justify-between items-center mb-6">
        <h1 class="text-3xl font-bold">Studios</h1>
        <.link
          :if={user_is_owner_in_any_org?(@current_user)}
          navigate={~p"/studios/new"}
          class="btn btn-primary"
        >
          New Studio
        </.link>
      </div>

      <.modal
        :if={@live_action in [:new, :edit]}
        id="studio-modal"
        show
        on_cancel={JS.navigate(~p"/studios")}
      >
        <.live_component
          module={PilatesOnPhxWeb.StudioLive.FormComponent}
          id={(@studio && @studio.id) || :new}
          title={@page_title}
          action={@live_action}
          studio={@studio}
          current_user={@current_user}
          navigate={~p"/studios"}
        />
      </.modal>

      <div class="overflow-x-auto">
        <table class="table w-full">
          <thead>
            <tr>
              <th>Name</th>
              <th>Address</th>
              <th>Timezone</th>
              <th>Max Capacity</th>
              <th>Status</th>
              <th class="text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={studio <- @studios} id={"studio-#{studio.id}"}>
              <td>
                <.link navigate={~p"/studios/#{studio}"} class="link link-hover">
                  {studio.name}
                </.link>
              </td>
              <td>{studio.address}</td>
              <td>{studio.timezone}</td>
              <td>{studio.max_capacity}</td>
              <td>
                <span class={[
                  "badge",
                  studio.active && "badge-success",
                  !studio.active && "badge-error"
                ]}>
                  {if studio.active, do: "Active", else: "Inactive"}
                </span>
              </td>
              <td class="text-right">
                <div :if={user_is_owner_in_any_org?(@current_user)} class="flex gap-2 justify-end">
                  <.link navigate={~p"/studios/#{studio}/edit"} class="btn btn-sm btn-ghost">
                    Edit
                  </.link>
                  <button
                    :if={studio.active}
                    phx-click="deactivate"
                    phx-value-id={studio.id}
                    data-confirm="Are you sure you want to deactivate this studio?"
                    class="btn btn-sm btn-ghost"
                  >
                    Deactivate
                  </button>
                  <button
                    phx-click="delete"
                    phx-value-id={studio.id}
                    data-confirm="Are you sure you want to delete this studio?"
                    class="btn btn-sm btn-error"
                  >
                    Delete
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>

        <div :if={@studios == []} class="text-center py-12 text-gray-500">
          No studios yet. Create your first studio to get started!
        </div>
      </div>
    </div>
    """
  end
end
