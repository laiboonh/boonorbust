defmodule BoonorbustWeb.Assets.AssetLive do
  use BoonorbustWeb, :live_view

  alias Boonorbust.Assets
  alias Boonorbust.Assets.Asset

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Assets
      <:subtitle><%= @action |> String.capitalize() %></:subtitle>
    </.header>

    <div class="space-y-12 divide-y">
      <div>
        <.simple_form for={@asset_form} id="asset_form" phx-submit={@action}>
          <.input field={@asset_form[:name]} label="Name" required />
          <.input field={@asset_form[:code]} label="Code" />
          <.input field={@asset_form[:root]} label="Root" type="checkbox" />
          <.input
            field={@asset_form[:tag_ids]}
            label="Tags"
            type="select"
            options={@tag_options}
            value={@selected_tag_values}
            multiple
          />
          <.input field={@asset_form[:user_id]} label="User ID" required readonly />
          <:actions>
            <.button phx-disable-with="..."><%= @action |> String.capitalize() %></.button>
          </:actions>
        </.simple_form>
      </div>
    </div>

    <%= if @assets != nil do %>
      <.table id="assets" rows={@assets}>
        <:col :let={asset} label="Id"><%= asset.id %></:col>
        <:col :let={asset} label="Name"><%= asset.name %></:col>
        <:col :let={asset} label="Code"><%= asset.code %></:col>
        <:col :let={asset} label="Root"><%= asset.root %></:col>
        <:col :let={asset} label="Tags"><%= tags(asset.tags) %></:col>
        <:col :let={asset} label="Action">
          <.link patch={~p"/assets/#{asset.id}"}><.icon name="hero-pencil-square-solid" /></.link>
          <.link patch={~p"/assets/new"}><.icon name="hero-document-plus-solid" /></.link>
          <span phx-click="delete" phx-value-id={asset.id}><.icon name="hero-trash-solid" /></span>
        </:col>
      </.table>
    <% end %>
    """
  end

  def tag_options(user_id) do
    Boonorbust.Tags.all(user_id) |> Enum.map(fn tag -> {tag.name, tag.id} end)
  end

  def tags(tags) do
    tags |> Enum.map_join(",", & &1.name)
  end

  def mount(%{"id" => id}, _session, socket) do
    user_id = socket.assigns.current_user.id

    socket =
      case Assets.get(id, user_id) do
        nil ->
          asset_changeset = Asset.changeset(%Asset{}, %{})

          socket
          |> assign(:assets, Assets.all(user_id))
          |> assign(:action, "update")
          |> assign(:asset_form, to_form(asset_changeset))
          |> put_flash(:error, "Asset #{id} not found")

        asset ->
          asset_changeset = Asset.changeset(asset, %{})

          socket
          |> assign(:assets, Assets.all(user_id))
          |> assign(:action, "update")
          |> assign(:tag_options, tag_options(user_id))
          |> assign(:asset_form, to_form(asset_changeset))
      end

    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id

    asset_changeset = Asset.changeset(%Asset{}, %{user_id: user_id})

    socket =
      socket
      |> assign(:assets, Assets.all(user_id))
      |> assign(:action, "insert")
      |> assign(:tag_options, tag_options(user_id))
      |> assign(:selected_tag_values, [])
      |> assign(:asset_form, to_form(asset_changeset))

    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    user_id = socket.assigns.current_user.id
    asset = Assets.get(id, user_id)
    asset_changeset = Asset.changeset(asset, %{})

    socket =
      socket
      |> assign(:assets, Assets.all(user_id))
      |> assign(:selected_tag_values, asset.tags |> Enum.map(& &1.id))
      |> assign(:action, "update")
      |> assign(:asset_form, to_form(asset_changeset))

    {:noreply, socket}
  end

  def handle_params(_params, _uri, socket) do
    user_id = socket.assigns.current_user.id

    socket =
      socket
      |> assign(:action, "insert")
      |> assign(:asset_form, to_form(Asset.changeset(%Asset{}, %{user_id: user_id})))

    {:noreply, socket}
  end

  def handle_event("insert", params, socket) do
    %{
      "asset" => %{
        "name" => name,
        "code" => code,
        "root" => root,
        "user_id" => user_id
      }
    } =
      params

    socket =
      case Assets.create(%{
             name: name,
             code: code,
             root: root,
             user_id: user_id,
             tag_ids: Map.get(params["asset"], "tag_ids", []) |> Enum.map(&String.to_integer(&1))
           }) do
        {:ok, asset} ->
          socket
          |> assign(:assets, Assets.all(user_id))
          |> assign(:asset_form, to_form(Asset.changeset(%Asset{}, %{user_id: user_id})))
          |> put_flash(:info, "Asset #{asset.name} Inserted")

        {:error, changeset} ->
          socket
          |> assign(:asset_form, to_form(Map.put(changeset, :action, :insert)))
          |> put_flash(:error, "Asset Insertion Failed")
      end

    {:noreply, socket}
  end

  def handle_event("update", params, socket) do
    user_id = socket.assigns.current_user.id
    %{hidden: [id: id]} = socket.assigns.asset_form

    %{"asset" => %{"name" => name, "code" => code, "root" => root}} = params

    socket =
      case Assets.update(id, user_id, %{
             name: name,
             code: code,
             root: root,
             tag_ids: Map.get(params["asset"], "tag_ids", []) |> Enum.map(&String.to_integer(&1))
           }) do
        {:ok, asset} ->
          info = "Asset #{asset.name} Updated"

          socket
          |> assign(:assets, Assets.all(user_id))
          |> put_flash(:info, info)

        {:error, changeset} ->
          assign(socket, :asset_form, to_form(Map.put(changeset, :action, :update)))
      end

    {:noreply, socket}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    user_id = socket.assigns.current_user.id

    socket =
      case Assets.delete(id, user_id) do
        {:ok, asset} ->
          info = "Asset #{asset.name} Deleted"

          socket
          |> assign(:assets, Assets.all(user_id))
          |> put_flash(:info, info)

        {:error, changeset} ->
          assign(socket, :asset_form, to_form(Map.put(changeset, :action, :delete)))
      end

    {:noreply, socket}
  end
end
