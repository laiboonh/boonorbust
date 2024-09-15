defmodule BoonorbustWeb.Portfolios.PortfolioLive do
  use BoonorbustWeb, :live_view

  alias Boonorbust.Portfolios
  alias Boonorbust.Portfolios.Portfolio

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Portfolios
      <:subtitle><%= @action |> String.capitalize() %></:subtitle>
    </.header>

    <div class="space-y-12 divide-y">
      <div>
        <.simple_form for={@portfolio_form} id="portfolio_form" phx-submit={@action}>
          <.input field={@portfolio_form[:name]} label="Name" required />
          <.input
            field={@portfolio_form[:tag_ids]}
            label="Tags"
            type="select"
            options={@tag_options}
            value={@selected_tag_values}
            multiple
          />
          <.input field={@portfolio_form[:user_id]} label="User ID" required readonly />
          <:actions>
            <.button phx-disable-with="..."><%= @action |> String.capitalize() %></.button>
          </:actions>
        </.simple_form>
      </div>
    </div>

    <%= if @portfolios != nil do %>
      <.table id="portfolios" rows={@portfolios}>
        <:col :let={portfolio} label="Id"><%= portfolio.id %></:col>
        <:col :let={portfolio} label="Name"><%= portfolio.name %></:col>
        <:col :let={portfolio} label="Tags"><%= tags(portfolio.tags) %></:col>
        <:col :let={portfolio} label="Action">
          <.link patch={~p"/portfolios/#{portfolio.id}"}>
            <.icon name="hero-pencil-square-solid" />
          </.link>
          <.link patch={~p"/portfolios"}><.icon name="hero-document-plus-solid" /></.link>
          <span phx-click="delete" phx-value-id={portfolio.id}>
            <.icon name="hero-trash-solid" />
          </span>
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
      case Portfolios.get(id, user_id) do
        nil ->
          portfolio_changeset = Portfolio.changeset(%Portfolio{}, %{})

          socket
          |> assign(:portfolios, Portfolios.all(user_id))
          |> assign(:action, "update")
          |> assign(:portfolio_form, to_form(portfolio_changeset))
          |> put_flash(:error, "Portfolio #{id} not found")

        portfolio ->
          portfolio_changeset = Portfolio.changeset(portfolio, %{})

          socket
          |> assign(:portfolios, Portfolios.all(user_id))
          |> assign(:action, "update")
          |> assign(:tag_options, tag_options(user_id))
          |> assign(:portfolio_form, to_form(portfolio_changeset))
      end

    {:ok, socket}
  end

  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id

    portfolio_changeset = Portfolio.changeset(%Portfolio{}, %{user_id: user_id})

    socket =
      socket
      |> assign(:portfolios, Portfolios.all(user_id))
      |> assign(:action, "insert")
      |> assign(:tag_options, tag_options(user_id))
      |> assign(:selected_tag_values, [])
      |> assign(:portfolio_form, to_form(portfolio_changeset))

    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    user_id = socket.assigns.current_user.id
    portfolio = Portfolios.get(id, user_id)
    portfolio_changeset = Portfolio.changeset(portfolio, %{})

    socket =
      socket
      |> assign(:portfolios, Portfolios.all(user_id))
      |> assign(:selected_tag_values, portfolio.tags |> Enum.map(& &1.id))
      |> assign(:action, "update")
      |> assign(:portfolio_form, to_form(portfolio_changeset))

    {:noreply, socket}
  end

  def handle_params(_params, _uri, socket) do
    user_id = socket.assigns.current_user.id

    socket =
      socket
      |> assign(:action, "insert")
      |> assign(:selected_tag_values, [])
      |> assign(:portfolio_form, to_form(Portfolio.changeset(%Portfolio{}, %{user_id: user_id})))

    {:noreply, socket}
  end

  def handle_event("insert", params, socket) do
    %{
      "portfolio" => %{
        "name" => name,
        "user_id" => user_id
      }
    } =
      params

    socket =
      case Portfolios.create(%{
             name: name,
             user_id: user_id,
             tag_ids:
               Map.get(params["portfolio"], "tag_ids", []) |> Enum.map(&String.to_integer(&1))
           }) do
        {:ok, portfolio} ->
          socket
          |> assign(:portfolios, Portfolios.all(user_id))
          |> assign(
            :portfolio_form,
            to_form(Portfolio.changeset(%Portfolio{}, %{user_id: user_id}))
          )
          |> put_flash(:info, "Portfolio #{portfolio.name} Inserted")

        {:error, changeset} ->
          socket
          |> assign(:portfolio_form, to_form(Map.put(changeset, :action, :insert)))
          |> put_flash(:error, "Portfolio Insertion Failed")
      end

    {:noreply, socket}
  end

  def handle_event("update", params, socket) do
    user_id = socket.assigns.current_user.id
    %{hidden: [id: id]} = socket.assigns.portfolio_form

    %{"portfolio" => %{"name" => name}} = params

    socket =
      case Portfolios.update(id, user_id, %{
             name: name,
             tag_ids:
               Map.get(params["portfolio"], "tag_ids", []) |> Enum.map(&String.to_integer(&1))
           }) do
        {:ok, portfolio} ->
          info = "Portfolio #{portfolio.name} Updated"

          socket
          |> assign(:portfolios, Portfolios.all(user_id))
          |> put_flash(:info, info)

        {:error, changeset} ->
          assign(socket, :portfolio_form, to_form(Map.put(changeset, :action, :update)))
      end

    {:noreply, socket}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    user_id = socket.assigns.current_user.id

    socket =
      case Portfolios.delete(id, user_id) do
        {:ok, portfolio} ->
          info = "Portfolio #{portfolio.name} Deleted"

          socket
          |> assign(:portfolios, Portfolios.all(user_id))
          |> put_flash(:info, info)

        {:error, changeset} ->
          assign(socket, :portfolio_form, to_form(Map.put(changeset, :action, :delete)))
      end

    {:noreply, socket}
  end
end
