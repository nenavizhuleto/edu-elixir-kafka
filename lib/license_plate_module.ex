defmodule LicensePlateModule do
  defmodule LicensePlate do
    defstruct [:class, :key, :confidence, :bounding_box]
  end
end

defmodule LicensePlateModule.Process do
  require Logger
  use GenServer

  @name __MODULE__

  def start_link(_args) do
    GenServer.start_link(__MODULE__, :ok, name: @name)
  end

  def init(:ok) do
    {:ok, %{}}
  end

  def detections(message) do
    GenServer.cast(@name, {:detections, message})
  end

  def view() do
    GenServer.call(@name, {:view})
  end

  def handle_cast({:detections, {timestamp, body}}, state) do
    {:ok, result} = Jason.decode(body)
    EventModule.Process.add(result["camera"], timestamp, result["detections"])
    new_state = Map.put(state, timestamp, result["detections"])
    {:noreply, new_state}
  end

  def handle_call({:view}, _from, state) do
    {:reply, state, state}
  end
end
