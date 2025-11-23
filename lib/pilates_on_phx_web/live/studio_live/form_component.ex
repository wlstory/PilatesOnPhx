defmodule PilatesOnPhxWeb.StudioLive.FormComponent do
  use PilatesOnPhxWeb, :live_component

  require Ash.Query

  @impl true
  def update(%{studio: studio} = assigns, socket) do
    actor = assigns.current_user
    organizations = get_user_owner_organizations(actor)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:organizations, organizations)
     |> assign_form(studio)}
  end

  defp get_user_owner_organizations(actor) do
    case Ash.load(actor, :organizations, domain: PilatesOnPhx.Accounts, authorize?: false) do
      {:ok, loaded_actor} ->
        loaded_actor.organizations
        |> List.wrap()
        |> Enum.filter(&user_is_owner_of_org?(&1, actor.id))

      _ ->
        []
    end
  end

  defp user_is_owner_of_org?(org, user_id) do
    case Ash.load(org, :memberships, domain: PilatesOnPhx.Accounts, authorize?: false) do
      {:ok, loaded_org} ->
        Enum.any?(loaded_org.memberships, fn m ->
          m.user_id == user_id && m.role == :owner
        end)

      _ ->
        false
    end
  end

  @impl true
  def handle_event("validate", %{"studio" => studio_params}, socket) do
    {:noreply, assign_form(socket, socket.assigns.studio, studio_params)}
  end

  @impl true
  def handle_event("save", %{"studio" => studio_params}, socket) do
    save_studio(socket, socket.assigns.action, studio_params)
  end

  defp save_studio(socket, :edit, studio_params) do
    actor = socket.assigns.current_user
    studio = socket.assigns.studio

    case studio
         |> Ash.Changeset.for_update(:update, studio_params, actor: actor)
         |> Ash.update(domain: PilatesOnPhx.Studios) do
      {:ok, studio} ->
        notify_parent({:saved, studio})

        {:noreply,
         socket
         |> put_flash(:info, "Studio updated successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to update studio")
         |> assign_form(socket.assigns.studio, studio_params)}
    end
  end

  defp save_studio(socket, :new, studio_params) do
    actor = socket.assigns.current_user

    case PilatesOnPhx.Studios.Studio
         |> Ash.Changeset.for_create(:create, studio_params, actor: actor)
         |> Ash.create(domain: PilatesOnPhx.Studios) do
      {:ok, studio} ->
        notify_parent({:saved, studio})

        {:noreply,
         socket
         |> put_flash(:info, "Studio created successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to create studio")
         |> assign_form(nil, studio_params)}
    end
  end

  defp assign_form(socket, studio, params \\ %{}) do
    form_data =
      if studio do
        %{
          "name" => studio.name,
          "address" => studio.address,
          "timezone" => studio.timezone,
          "max_capacity" => studio.max_capacity,
          "organization_id" => studio.organization_id
        }
        |> Map.merge(params)
      else
        params
      end

    form = to_form(form_data)

    assign(socket, :form, form)
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-2xl font-bold mb-4">
        {(@action == :new && "Create Studio") || @title}
      </h2>

      <.form
        for={@form}
        id="studio-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="form-control w-full mb-4">
          <label class="label">
            <span class="label-text">Studio Name</span>
          </label>
          <input
            type="text"
            name="studio[name]"
            value={@form["name"].value}
            class="input input-bordered w-full"
            required
          />
        </div>

        <div class="form-control w-full mb-4">
          <label class="label">
            <span class="label-text">Address</span>
          </label>
          <input
            type="text"
            name="studio[address]"
            value={@form["address"].value}
            class="input input-bordered w-full"
            required
          />
        </div>

        <div class="form-control w-full mb-4">
          <label class="label">
            <span class="label-text">Timezone</span>
          </label>
          <select name="studio[timezone]" class="select select-bordered w-full">
            <option value="America/New_York" selected={@form["timezone"].value == "America/New_York"}>
              Eastern Time (America/New_York)
            </option>
            <option value="America/Chicago" selected={@form["timezone"].value == "America/Chicago"}>
              Central Time (America/Chicago)
            </option>
            <option value="America/Denver" selected={@form["timezone"].value == "America/Denver"}>
              Mountain Time (America/Denver)
            </option>
            <option
              value="America/Los_Angeles"
              selected={@form["timezone"].value == "America/Los_Angeles"}
            >
              Pacific Time (America/Los_Angeles)
            </option>
          </select>
        </div>

        <div class="form-control w-full mb-4">
          <label class="label">
            <span class="label-text">Max Capacity</span>
          </label>
          <input
            type="number"
            name="studio[max_capacity]"
            value={@form["max_capacity"].value}
            class="input input-bordered w-full"
            min="1"
            max="500"
            required
          />
        </div>

        <div :if={@action == :new} class="form-control w-full mb-4">
          <label class="label">
            <span class="label-text">Organization</span>
          </label>
          <select name="studio[organization_id]" class="select select-bordered w-full" required>
            <option value="">Select an organization</option>
            <option
              :for={org <- @organizations}
              value={org.id}
              selected={@form["organization_id"].value == org.id}
            >
              {org.name}
            </option>
          </select>
        </div>

        <div class="modal-action">
          <button type="submit" class="btn btn-primary">
            Save
          </button>
          <button type="button" phx-click={JS.exec("data-cancel", to: "#studio-modal")} class="btn">
            Cancel
          </button>
        </div>
      </.form>
    </div>
    """
  end
end
