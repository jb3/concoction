defmodule Concoction.Gateway.Heartbeater do
  use GenServer

  alias Concoction.Gateway.Payload

  require Logger

  @doc """
  Start the heartbeater with the milliseconds and connection PID passed.
  """
  @spec start_link(integer()) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(heartbeat_interval) do
    Logger.debug("Heartbeater starting")
    GenServer.start_link(__MODULE__, heartbeat_interval, name: __MODULE__)
  end

  @impl GenServer
  @spec init({integer(), pid()}) :: {:ok, {integer(), integer()}}
  def init(heartbeat_interval) do
    Logger.debug("Scheduling first heartbeat")
    parent = self()

    spawn(fn ->
      Process.sleep(heartbeat_interval)
      GenServer.cast(parent, :heartbeat)
    end)

    {:ok, {heartbeat_interval, 0}}
  end

  @impl GenServer
  def handle_cast({:new_sequence, new_seq}, {heartbeat_interval, _old_seq}) do
    Logger.debug("Updating new sequence number: #{new_seq}")
    {:noreply, {heartbeat_interval, new_seq}}
  end

  @impl GenServer
  def handle_cast(:heartbeat, state = {heartbeat_interval, last_sequence}) do
    Logger.debug("Preparing heartbeat payload")

    payload = %Payload{
      op: 1,
      d: last_sequence
    }

    GenServer.cast(Concoction.Gateway.Connection, {:send, payload})

    Logger.debug("Heartbeating and scheduling next heartbeat <3")

    parent = self()

    spawn(fn ->
      Process.sleep(heartbeat_interval)
      GenServer.cast(parent, :heartbeat)
    end)

    {:noreply, state}
  end
end
