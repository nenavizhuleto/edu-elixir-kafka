defmodule Analytics do
  alias EventModule
  alias LicensePlateModule
  require Logger
  use GenServer

  @name __MODULE__

  @topic "results"
  @partition 0

  use Application

  def start(_type, _args) do
    children = [
      LicensePlateModule.Process,
      EventModule.Process,
      Analytics
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def start_link(_args) do
    GenServer.start_link(@name, :ok, [])
  end

  def init(:ok) do
    :brod.start_consumer(:kafka_client, @topic, begin_offset: :latest)
    :brod.subscribe(:kafka_client, self(), @topic, @partition, [])
    {:ok, %{}}
  end

  def handle_info(
        {_pid,
         {
           :kafka_message_set,
           _topic,
           _partition,
           _next_offset,
           messages
         }},
        state
      ) do
    for message <- messages do
      {:kafka_message, _offset, key, body, _op, timestamp, headers} = message

      case key do
        "LicensePlate" ->
          LicensePlateModule.detections({timestamp, body})

        "Motion" ->
          [{"camera", camera} | _rest] = headers
          EventModule.Process.start(camera, timestamp)

        _ ->
          :unknown
      end
    end

    {:noreply, state}
  end
end
