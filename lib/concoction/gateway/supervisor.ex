defmodule Concoction.Gateway.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    {:ok, websocket_url, shard_count} = Concoction.API.Gateway.get_gateway_bot()

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
