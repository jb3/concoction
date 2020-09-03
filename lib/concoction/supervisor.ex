defmodule Concoction.Supervisor do
  @moduledoc """
  Managing the processes for Concoction.
  """
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      {Mutex, name: Concoction.Mutex},
      {Concoction.Gateway.Supervisor, name: Concoction.Gateway.Supervisor}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
