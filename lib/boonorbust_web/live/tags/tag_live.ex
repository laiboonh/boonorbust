defmodule BoonorbustWeb.Tags.TagLive do
  use BoonorbustWeb, :live_view

  alias Boonorbust.Tags
  alias Boonorbust.Tags.Tag

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Tags
      <:subtitle><%= @action |> String.capitalize() %></:subtitle>
    </.header>

    <div class="space-y-12 divide-y">
      <div>
        <.simple_form for={@tag_form} id="tag_form" phx-submit={@action}>
          <.input field={@tag_form[:name]} label="Name" required />
          <.input field={@tag_form[:user_id]} label="User ID" required readonly />
          <:actions>
            <.button phx-disable-with="..."><%= @action |> String.capitalize() %></.button>
          </:actions>
        </.simple_form>
      </div>
    </div>

    <%= if @tags != nil do %>
      <.table id="tags" rows={@tags}>
        <:col :let={tag} label="Id"><%= tag.id %></:col>
        <:col :let={tag} label="Name"><%= tag.name %></:col>
        <:col :let={tag} label="Action">
          <.link patch={~p"/tags/#{tag.id}"}><.icon name="hero-pencil-square-solid" /></.link>
          <.link patch={~p"/tags/new"}><.icon name="hero-document-plus-solid" /></.link>
          <span phx-click="delete" phx-value-id={tag.id}><.icon name="hero-trash-solid" /></span>
        </:col>
      </.table>
    <% end %>
    """
  end

  def mount(%{"id" => id}, _session, socket) do
    user_id = socket.assigns.current_user.id

    socket =
      case Tags.get(id, user_id) do
        nil ->
          tag_changeset = Tag.changeset(%Tag{}, %{})

          socket
          |> assign(:tags, Tags.all(user_id))
          |> assign(:action, "update")
          |> assign(:tag_form, to_form(tag_changeset))
          |> put_flash(:error, "Tag #{id} not found")

        tag ->
          tag_changeset = Tag.changeset(tag, %{})

          socket
          |> assign(:tags, Tags.all(user_id))
          |> assign(:action, "update")
          |> assign(:tag_form, to_form(tag_changeset))
      end

    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id

    tag_changeset = Tag.changeset(%Tag{}, %{user_id: user_id})

    socket =
      socket
      |> assign(:tags, Tags.all(user_id))
      |> assign(:action, "insert")
      |> assign(:tag_form, to_form(tag_changeset))

    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    user_id = socket.assigns.current_user.id
    tag = Tags.get(id, user_id)
    tag_changeset = Tag.changeset(tag, %{})

    socket =
      socket
      |> assign(:tags, Tags.all(user_id))
      |> assign(:action, "update")
      |> assign(:tag_form, to_form(tag_changeset))

    {:noreply, socket}
  end

  def handle_params(_params, _uri, socket) do
    user_id = socket.assigns.current_user.id

    socket =
      socket
      |> assign(:action, "insert")
      |> assign(:tag_form, to_form(Tag.changeset(%Tag{}, %{user_id: user_id})))

    {:noreply, socket}
  end

  def handle_event("insert", params, socket) do
    %{"tag" => %{"name" => name, "user_id" => user_id}} = params

    socket =
      case Tags.create(%{name: name, user_id: user_id}) do
        {:ok, tag} ->
          socket
          |> assign(:tags, Tags.all(user_id))
          |> assign(:tag_form, to_form(Tag.changeset(%Tag{}, %{user_id: user_id})))
          |> put_flash(:info, "Tag #{tag.name} Inserted")

        {:error, changeset} ->
          socket
          |> assign(:tag_form, to_form(Map.put(changeset, :action, :insert)))
          |> put_flash(:error, "Tag Insertion Failed")
      end

    {:noreply, socket}
  end

  def handle_event("update", params, socket) do
    user_id = socket.assigns.current_user.id
    %{hidden: [id: id]} = socket.assigns.tag_form

    %{"tag" => %{"name" => name}} = params

    socket =
      case Tags.update(id, user_id, %{name: name}) do
        {:ok, tag} ->
          info = "Tag #{tag.name} Updated"

          socket
          |> assign(:tags, Tags.all(user_id))
          |> put_flash(:info, info)

        {:error, changeset} ->
          assign(socket, :tag_form, to_form(Map.put(changeset, :action, :update)))
      end

    {:noreply, socket}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    user_id = socket.assigns.current_user.id

    socket =
      case Tags.delete(id, user_id) do
        {:ok, tag} ->
          info = "Tag #{tag.name} Deleted"

          socket
          |> assign(:tags, Tags.all(user_id))
          |> put_flash(:info, info)

        {:error, changeset} ->
          assign(socket, :tag_form, to_form(Map.put(changeset, :action, :delete)))
      end

    {:noreply, socket}
  end
end
