defmodule EventModule do
  require Logger

  defmodule Event do
    defstruct [:id, :producer, :start, :end, :duration, :detections]

    defp now() do
      DateTime.utc_now(:millisecond)
    end

    defp ts(timestamp) when is_integer(timestamp) do
      {:ok, time} = DateTime.from_unix(timestamp, :millisecond)
      time
    end

    def start(producer) do
      %Event{
        id: UUID.uuid4(),
        producer: producer,
        start: now(),
        detections: %{}
      }
    end

    def start(producer, timestamp) when is_integer(timestamp) do
      start = ts(timestamp)

      %Event{
        id: UUID.uuid4(),
        producer: producer,
        start: start,
        detections: %{}
      }
    end

    def stop(event) do
      stop = now()

      event
      |> Map.put(:end, stop)
      |> Map.put(:duration, DateTime.diff(stop, event.start))
    end

    def stop(event, timestamp) when is_integer(timestamp) do
      stop = ts(timestamp)

      event
      |> Map.put(:end, stop)
      |> Map.put(:duration, DateTime.diff(stop, event.start))
    end

    def add_detection(event, timestamp, detection) when is_integer(timestamp) do
      detections = Map.merge(event.detections, %{ts(timestamp) => detection})
      Map.put(event, :detections, detections)
    end
  end
end

defmodule EventModule.Process do
  alias EventModule.Event
  use GenServer
  @name __MODULE__

  def start_link(_args) do
    GenServer.start_link(__MODULE__, :ok, name: @name)
  end

  def init(:ok) do
    {:ok, %{}}
  end

  def start(producer, timestamp) do
    GenServer.cast(@name, {:start, producer, timestamp})
  end

  def add(producer, timestamp, value) do
    GenServer.cast(@name, {:add, producer, {timestamp, value}})
  end

  def view() do
    GenServer.call(@name, {:view})
  end

  def handle_cast({:add, producer, {timestamp, detection}}, state) do
    state =
      case Map.fetch(state, producer) do
        {:ok, event} ->
          event = Event.add_detection(event, timestamp, detection)
          Map.put(state, producer, event)

        :error ->
          state
      end

    {:noreply, state}
  end

  def handle_cast({:start, producer, timestamp}, state) do
    with {:ok, event} <- Map.fetch(state, producer) do
      event = Event.stop(event, timestamp)
      IO.inspect(event)
    end

    event = Event.start(producer, timestamp)
    state = Map.put(state, producer, event)
    {:noreply, state}
  end

  def handle_call({:view}, _from, state) do
    {:reply, state, state}
  end
end
