defmodule Concoction.Gateway.Connection do
  use GenServer

  require Logger

  alias Concoction.Gateway.Payload

  @doc """
  Start a connection to the Discord Gateway.
  """
  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_state) do
    Logger.debug "Fetching gateway information and starting connenction to Gateway"
    {:ok, websocket_url, _shards} = Concoction.API.Gateway.get_gateway_bot()

    GenServer.start_link(
      __MODULE__,
      websocket_url,
      name: __MODULE__
    )
  end

  @impl GenServer
  @spec init(String.t()) :: {:ok, pid}
  def init(websocket_url) do
    uri = URI.parse(websocket_url)

    Logger.debug "Starting connection to Gateway"

    {:ok, conn_pid} = :gun.open(uri.host |> String.to_charlist, 443, %{protocols: [:http]})
    {:ok, _protocol} = :gun.await_up(conn_pid)

    :gun.ws_upgrade(conn_pid, '/?v=6&encoding=etf')
    {:ok, conn_pid}
  end

  @impl GenServer
  def handle_cast({:send, payload}, state) do
    Logger.debug "Sending payload with opcode #{payload.op} to gateway"

    :gun.ws_send(state, {:binary, payload |> Payload.to_etf()})

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:gun_ws, _conn, _ref, {:binary, data}}, state) do
    Logger.debug "Handing incoming payload to Handler"
    data = :erlang.binary_to_term(data)

    GenServer.cast(Concoction.Gateway.Handler, data)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(msg, state) do
    Logger.debug("Unhandled gun gateway message: #{inspect(msg)}")
    {:noreply, state}
  end
end
