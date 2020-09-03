defmodule Concoction.Gateway.Supervisor do
  @moduledoc """
  Supervisor to manage the shards responsible for communicating with the Discord gateway.

  Shards are added when the supervisor starts by fetching the estimated shard count from Discord.
  """

  use Supervisor

  alias Concoction.API.Gateway

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    {:ok, websocket_url, shard_count} = Gateway.get_gateway_bot()

    children =
      Enum.map(1..shard_count, fn shard_id ->
        shard_array = [shard_id - 1, shard_count]

        %{
          id: :"Concoction-shard-#{shard_id}",
          start: {Concoction.Gateway.Connection, :start_link, [{websocket_url, shard_array}]}
        }
      end)

    Supervisor.init(children, strategy: :one_for_one)
  end
end
