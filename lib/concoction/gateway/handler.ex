defmodule Concoction.Gateway.Handler do
  use GenServer

  require Logger

  alias Concoction.Gateway.Payload

  def start_link(state) do
    Logger.debug("Starting Gateway Handler")
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl GenServer
  @spec init(any) :: {:ok, any}
  def init(state) do
    {:ok, state}
  end

  @impl GenServer
  def handle_cast(data, state) do
    payload = struct(Payload, data)

    Logger.debug("Handling incoming event with opcode #{payload.op}")

    if payload.s do
      GenServer.cast(Concoction.Gateway.Heartbeater, {:new_sequence, payload.s})
    end

    handle_event(payload)

    {:noreply, state}
  end

  @spec handle_event(Concoction.Gateway.Payload.t()) :: any()
  @doc """
  Handle parsed gateway events from the Discord gateway.
  """
  def handle_event(payload = %Payload{op: 10}) do
    Logger.debug(
      "HELLO payload received, heartbeating every #{payload.d.heartbeat_interval} millieconds"
    )

    Supervisor.start_child(
      Concoction.Supervisor,
      {Concoction.Gateway.Heartbeater, payload.d.heartbeat_interval}
    )

    identify_payload = %Payload{
      op: 2,
      d: %{
        token: "Bot " <> Application.fetch_env!(:concoction, :token),
        properties: %{
          "$os": :os.type() |> elem(1) |> Atom.to_string(),
          "$browser": "concoction",
          "$device": "concoction"
        }
      }
    }

    GenServer.cast(Concoction.Gateway.Connection, {:send, identify_payload})
  end

  def handle_event(payload = %Payload{op: 0, t: :READY}) do
    Logger.debug("READY payload received")

    IO.inspect(payload.d)
  end

  def handle_event(payload) do
    Logger.debug("Unhandled payload opcode: #{payload.op}, event type: #{payload.t}")
  end
end
