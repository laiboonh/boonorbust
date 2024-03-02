defmodule BoonorbustWeb.Assets.AssetLive do
  use BoonorbustWeb, :live_view

  alias Boonorbust.Assets
  alias Boonorbust.Assets.Asset

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Assets
      <:subtitle><%= @action %></:subtitle>
    </.header>

    <div class="space-y-12 divide-y">
      <div>
        <.simple_form for={@asset_form} id="asset_form" phx-submit={@action}>
          <.input field={@asset_form[:name]} label="Name" required />
          <.input field={@asset_form[:user_id]} label="User ID" required readonly />
          <:actions>
            <.button phx-disable-with="..."><%= @action %></.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  def mount(%{"id" => id}, _session, socket) do
    socket =
      case Assets.get(id) do
        nil ->
          asset_changeset = Asset.changeset(%Asset{}, %{})

          socket
          |> assign(:action, "update")
          |> assign(:asset_form, to_form(asset_changeset))
          |> put_flash(:error, "Asset #{id} not found")

        asset ->
          asset_changeset = Asset.changeset(asset, %{})

          socket
          |> assign(:action, "update")
          |> assign(:asset_form, to_form(asset_changeset))
          |> assign(:trigger_submit, false)
      end

    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    asset_changeset = Asset.changeset(%Asset{}, %{user_id: user.id})

    socket =
      socket
      |> assign(:action, "insert")
      |> assign(:asset_form, to_form(asset_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  def handle_event("insert", params, socket) do
    %{"asset" => %{"name" => name, "user_id" => user_id}} = params

    case Assets.create(%{name: name, user_id: user_id}) do
      {:ok, asset} ->
        info = "Asset #{asset.name} Inserted"
        {:noreply, socket |> put_flash(:info, info)}

      {:error, changeset} ->
        {:noreply, assign(socket, :asset_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("update", params, socket) do
    %{hidden: [id: id]} = socket.assigns.asset_form

    %{"asset" => %{"name" => name}} = params

    case Assets.update(id, %{name: name}) do
      {:ok, asset} ->
        info = "Asset #{asset.name} Updated"
        {:noreply, socket |> put_flash(:info, info)}

      {:error, changeset} ->
        {:noreply, assign(socket, :asset_form, to_form(Map.put(changeset, :action, :update)))}
    end
  end
end
