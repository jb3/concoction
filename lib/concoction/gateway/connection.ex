defmodule Concoction.Gateway.Connection do
  @moduledoc """
  Maintaining the connection to Discord and performing the first parsing of payloads before handing them down the chain.
  """
  use GenServer

  require Logger

  alias Concoction.Gateway.Payload

  @doc """
  Start a connection to the Discord Gateway.
  """
  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(configuration) do
    GenServer.start_link(
      __MODULE__,
      configuration,
      name: :"Concoction-shard-#{configuration |> elem(1) |> Enum.at(0)}"
    )
  end

  @impl GenServer
  @spec init({String.t(), list(integer())}) :: {:ok, {pid, pid, integer() | nil}}
  def init({websocket_url, [shard_id, shard_count]}) do
    uri = URI.parse(websocket_url)

    Logger.debug("Starting connection to Gateway on shard #{shard_id}")

    {:ok, conn_pid} = :gun.open(uri.host |> String.to_charlist(), 443, %{protocols: [:http]})
    {:ok, _protocol} = :gun.await_up(conn_pid)

    :gun.ws_upgrade(conn_pid, '/?v=6&encoding=etf')

    {:ok, handler_pid} = GenServer.start_link(Concoction.Gateway.Handler, [shard_id, shard_count])

    {:ok, {conn_pid, handler_pid, nil}}
  end

  @impl GenServer
  def handle_cast({:send, payload}, state = {conn_pid, _, _}) do
    Logger.debug("Sending payload with opcode #{payload.op} to gateway")

    :gun.ws_send(conn_pid, {:binary, payload |> Payload.to_etf()})

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:close, state = {conn_pid, _handler_pid, last_seq}) do
    :gun.ws_send(conn_pid, :close)

    {:stop, :reconnect, state}
  end

  @impl GenServer
  def handle_info({:gun_ws, _conn, _ref, {:binary, data}}, state = {_, handler_pid, _}) do
    data = :erlang.binary_to_term(data)

    GenServer.cast(handler_pid, data)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(
        {:gun_down, _conn, _proto, _reason, _killed_streams, _unprocessed_streams},
        state
      ) do
    Logger.debug("Gun gateway down")
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(msg, state) do
    Logger.debug("Unhandled gun gateway message: #{inspect(msg)}")
    {:noreply, state}
  end
end
