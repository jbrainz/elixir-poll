defmodule PollingAppWeb.PollLive do
  use PollingAppWeb, :live_view
  alias PollingApp.Poll
  alias PollingApp.Polls.Poll
  alias PollingApp.PollManager.PollManager

  def mount(_params, _session, socket) do
    changeset = Poll.changeset(%Poll{}, %{})
    polls = PollManager.get_polls()
    option1 = ["Yes", "True"]
    option2 = ["No", "False"]

    socket =
      socket
      |> assign(:form, to_form(changeset))
      |> assign(
        polls: polls,
        option1: option1,
        option2: option2,
        is_polls_visible: false
      )

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <div class="m-2 my-4 p-4">
        <div>
          <h2 class="text-xl">Create a Poll</h2>
          <.form for={@form} phx-change="validate" phx-submit="save">
            <.input type="text" field={@form[:title]} placeholder="Poll Title" />
            <.input
              type="select"
              label="Option 1"
              prompt="Select an option"
              name="option1"
              options={@option1}
              field={@form[:option1]}
              placeholder="Option 1"
            />
            <.input
              type="select"
              name="option2"
              label="Option 2"
              prompt="Select an option"
              options={@option2}
              field={@form[:option2]}
              placeholder="Option 2"
            />
            <button
              type="submit"
              class="border mt-2 rounded-md px-4 py-2 border-gray-500  bg-slate-600 text-white"
            >
              Create Poll
            </button>
          </.form>

          <button
            type="click"
            class="border mt-2 rounded-md px-4 py-2 border-gray-500  bg-slate-600 text-white"
            phx-click="toggle_polls"
          >
            <%= if @is_polls_visible, do: "Close Polls", else: "View Polls" %>
          </button>
        </div>
      </div>
      <div class={unless @is_polls_visible, do: "hidden"}>
        <h2>Vote on Polls</h2>
        <table class="border max-h-screen border-gray-300">
          <thead>
            <tr>
              <th class="px-2 border-b border-gray-300">Title</th>
              <th class="border-b border-gray-300">Options</th>
            </tr>
          </thead>
          <tbody>
            <%= for poll <- @polls do %>
              <tr>
                <td class="border-b px-4 border-gray-300 border">
                  <span class="text-sm font-bold">
                    <%= poll.title %>
                  </span>
                </td>
                <td class="border-b border-gray-300 p-4">
                  <div class="flex flex-row pl-6 space-x-4 justify-between">
                    <%= for option <- poll.options do %>
                      <button
                        phx-click="vote"
                        type="button"
                        phx-value-poll={option.value}
                        phx-value-poll_id={poll.id}
                        class="border min-w-16 rounded-md px-4 py-1 border-gray-500 bg-blue-600 text-white"
                      >
                        <%= option.value %>
                      </button>
                      <span>No of Votes: <%= option.votes %></span>
                    <% end %>
                  </div>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  def handle_event(
        "save",
        %{"poll" => %{"title" => title}, "option1" => option1, "option2" => option2},
        socket
      ) do
    options = [option1, option2]

    form_errors = socket.assigns.form

    if form_errors.source.valid? do
      case PollManager.create_poll(title, options) do
        :ok -> {:noreply, assign(socket, polls: PollManager.get_polls())}
        {:error, changeset} -> {:noreply, assign(socket, form: to_form(changeset))}
      end
    else
      changeset =
        %Poll{}
        |> Poll.changeset(%{title: title, option1: option1, option2: option2})

      {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("toggle_polls", _unsigned_params, socket) do
    {:noreply, assign(socket, is_polls_visible: !socket.assigns.is_polls_visible)}
  end

  def handle_event(
        "validate",
        %{"poll" => changed_params, "option1" => option1, "option2" => option2},
        socket
      ) do
    params = Map.merge(changed_params, %{"option1" => option1, "option2" => option2})

    changeset =
      %Poll{}
      |> Poll.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("vote", %{"poll_id" => poll_id, "poll" => option}, socket) do
    _new_state = PollManager.vote(poll_id, option)
    {:noreply, assign(socket, polls: PollManager.get_polls())}
  end
end
