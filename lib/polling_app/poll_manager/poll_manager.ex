defmodule PollingApp.PollManager.PollManager do
  @name :poll_manager

  use GenServer

  defmodule State do
    defstruct cache_size: 5, polls: []
  end

  def start_link(_state) do
    GenServer.start_link(__MODULE__, %State{}, name: @name)
  end

  def create_poll(title, options) do
    GenServer.call(@name, {:create_poll, title, options})
  end

  def vote(poll_id, option) do
    GenServer.call(@name, {:vote, poll_id, option})
  end

  def get_polls do
    GenServer.call(@name, :get_polls)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call({:create_poll, title, options}, _from, state) do
    most_recent_poll = Enum.take(state.polls, state.cache_size - 1)

    poll = %{
      title: title,
      options: Enum.map(options, fn option -> %{value: option, votes: 0} end),
      id: Enum.count(state.polls) + 1
    }

    cached_polls = [poll | most_recent_poll]
    new_state = %{state | polls: cached_polls}
    {:reply, :ok, new_state}
  end

  def handle_call({:vote, poll_id, option}, _from, state) do
    parse_poll_id = Integer.parse(poll_id) |> elem(0)

    new_polls =
      Enum.map(state.polls, fn poll ->
        if poll.id == parse_poll_id do
          new_options =
            Enum.map(poll.options, fn poll_option ->
              if poll_option.value == option do
                %{poll_option | votes: poll_option.votes + 1}
              else
                poll_option
              end
            end)

          %{poll | options: new_options}
        else
          poll
        end
      end)

    {:reply, new_polls, %{state | polls: new_polls}}
  end

  def handle_call(:get_polls, _from, state) do
    {:reply, state.polls, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end
