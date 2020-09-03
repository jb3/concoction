defmodule Concoction.Gateway.Handler do
  @moduledoc """
  Handling events coming from Discord in a nicer, parsed fashion.
  """
  use GenServer

  require Logger

  alias Concoction.Gateway.Payload

  @spec start_link(list(integer())) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(shard_info) do
    Logger.debug("Starting Gateway Handler")
    GenServer.start_link(__MODULE__, shard_info)
  end

  @impl GenServer
  @spec init(list(integer)) :: {:ok, {list(integer), integer() | nil, integer() | nil}}
  def init(shard_info) do
    {:ok, {shard_info, nil, nil}}
  end

  @impl GenServer
  def handle_cast(data, state) do
    payload = struct(Payload, data)

    Logger.debug("Handling incoming event with opcode #{payload.op}")

    state = if payload.s do
      {elem(state, 0), elem(state, 1), payload.s}
    else
      state
    end

    handle_event(payload, state)
  end

  @impl GenServer
  def handle_call(:heartbeat, _from, state = {shard_info, heartbeat_interval, last_s}) do
    heartbeat = %Payload{
      op: 1,
      d: last_s
    }

    GenServer.cast(get_connection(shard_info), {:send, heartbeat})

    parent = self()

    spawn fn ->
      Process.sleep(heartbeat_interval)
      GenServer.call(parent, :heartbeat)
    end

    {:noreply, state}
  end

  defp get_shard(shard_info) do
    Enum.at shard_info, 0
  end

  defp get_connection(shard_info) do
    :"Concoction-shard-#{get_shard(shard_info)}"
  end

  @spec handle_event(Concoction.Gateway.Payload.t(), tuple()) :: any()
  @doc """
  Handle parsed gateway events from the Discord gateway.
  """
  def handle_event(payload = %Payload{op: 10}, {shard_info, _, last_s}) do
    Logger.debug(
      "HELLO payload received, heartbeating every #{payload.d.heartbeat_interval} millieconds"
    )

    parent = self()
    spawn fn ->
      Process.sleep(payload.d.heartbeat_interval)
      GenServer.call(parent, :heartbeat)
    end

    identify_payload = %Payload{
      op: 2,
      d: %{
        token: "Bot " <> Application.fetch_env!(:concoction, :token),
        shard: shard_info,
        properties: %{
          "$os": :os.type() |> elem(1) |> Atom.to_string(),
          "$browser": "concoction",
          "$device": "concoction"
        }
      }
    }

    lock = Mutex.await(Concoction.Mutex, :identify, :infinity)

    Logger.debug("Sending IDENTIFY payload for shard #{get_shard(shard_info)}")

    GenServer.cast(get_connection(shard_info), {:send, identify_payload})

    Process.sleep(5100)

    Logger.debug("Unlocking IDENTIFY ratelimit mutex")
    Mutex.release(Concoction.Mutex, lock)

    {:noreply, {shard_info, payload.d.heartbeat_interval, last_s}}
  end

  def handle_event(_payload = %Payload{op: 0, t: :READY}, state = {shard_info, _, _}) do
    Logger.debug("Shard #{get_shard(shard_info)} received READY payload")
    {:noreply, state}
  end

  def handle_event(%Payload{op: 11}, state) do
    # Ignore heartbeat ACK
    {:noreply, state}
  end

  def handle_event(payload, state = {shard_info, _, _}) do
    Logger.debug("Unhandled payload on shard ##{get_shard(shard_info)} opcode: #{payload.op}, event type: #{payload.t}")
    {:noreply, state}
  end
end
