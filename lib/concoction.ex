defmodule Concoction do
  @moduledoc """
  Concoction is a Discord library for Elixir.
  """
  use Application

  @impl true
  def start(_type, _args) do
    # Initialise storage for ratelimit buckets
    Concoction.HTTP.init()

    Concoction.Supervisor.start_link(name: Concoction.Supervisor)
  end
end
