defmodule PilatesOnPhxWeb.StudioLive.FormComponent do
  use PilatesOnPhxWeb, :live_component

  require Ash.Query

  @impl true
  def update(%{studio: studio} = assigns, socket) do
    actor = assigns.current_user
    organizations = get_user_owner_organizations(actor)

    form =
      if studio do
        AshPhoenix.Form.for_update(studio, :update,
          domain: PilatesOnPhx.Studios,
          actor: actor,
          as: "studio"
        )
      else
        # Auto-select first organization for new studios
        default_org_id =
          if Enum.empty?(organizations), do: nil, else: List.first(organizations).id

        AshPhoenix.Form.for_create(PilatesOnPhx.Studios.Studio, :create,
          domain: PilatesOnPhx.Studios,
          actor: actor,
          as: "studio",
          params: %{"organization_id" => default_org_id}
        )
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:organizations, organizations)
     |> assign(:form, to_form(form))}
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
    form = AshPhoenix.Form.validate(socket.assigns.form.source, studio_params)

    {:noreply, assign(socket, :form, to_form(form))}
  end

  @impl true
  def handle_event("save", %{"studio" => studio_params}, socket) do
    # Validate form first
    form = AshPhoenix.Form.validate(socket.assigns.form.source, studio_params)

    case AshPhoenix.Form.submit(form, params: studio_params) do
      {:ok, studio} ->
        notify_parent({:saved, studio})
        {:noreply, socket}

      {:error, form} ->
        {:noreply, assign(socket, :form, to_form(form))}
    end
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
        <.input field={@form[:name]} type="text" label="Studio Name" required />
        <.input field={@form[:address]} type="text" label="Address" required />

        <.input
          field={@form[:timezone]}
          type="select"
          label="Timezone"
          options={[
            {"Eastern Time (America/New_York)", "America/New_York"},
            {"Central Time (America/Chicago)", "America/Chicago"},
            {"Mountain Time (America/Denver)", "America/Denver"},
            {"Pacific Time (America/Los_Angeles)", "America/Los_Angeles"}
          ]}
        />

        <.input
          field={@form[:max_capacity]}
          type="number"
          label="Max Capacity"
          min="1"
          max="500"
          required
        />

        <.input
          :if={@action == :new}
          field={@form[:organization_id]}
          type="select"
          label="Organization"
          options={[{"Select an organization", ""} | Enum.map(@organizations, &{&1.name, &1.id})]}
          required
        />

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
