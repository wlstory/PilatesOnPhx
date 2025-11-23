defmodule PilatesOnPhxWeb.StudioLive.Show do
  use PilatesOnPhxWeb, :live_view

  on_mount {PilatesOnPhxWeb.UserAuth, :default}

  require Ash.Query

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
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
         |> push_navigate(to: ~p"/studios")}
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

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <div class="flex justify-between items-center mb-6">
        <h1 class="text-3xl font-bold">{@studio.name}</h1>
        <div class="flex gap-2">
          <.link navigate={~p"/studios/#{@studio}/edit"} class="btn btn-primary">
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
          </div>

          <div class="card-actions justify-end mt-4">
            <button
              :if={!@studio.active}
              phx-click="activate"
              class="btn btn-success"
            >
              Activate Studio
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
