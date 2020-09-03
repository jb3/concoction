defmodule Concoction.Gateway.Payload do
  defstruct [:op, :d, :s, :t]

  @moduledoc """
  Struct and relevant utilities for operating on structures coming to and from the Discord Gateway.
  """

  @typedoc """
  Opcode for the Payload.
  """
  @type op :: integer()

  @typedoc """
  Event data in the payload.
  """
  @type d :: any()

  @typedoc """
  Sequence number, used for resuming sessions and heartbeats
  """
  @type s :: integer() | nil

  @typedoc """
  Event name of the payload.
  """
  @type event_name :: String.t() | nil

  @type t :: %__MODULE__{
    op: op,
    d: d,
    s: s,
    t: event_name
  }

  @doc """
  Convert the payload into ETF ready for sending to the gateway.
  """
  @spec to_etf(%__MODULE__{}) :: binary
  def to_etf(payload) do
    Map.from_struct(payload)
    |> Enum.reduce(%{}, fn {attr, val}, acc ->
      if val != nil do
        Map.put acc, attr, val
      else
        acc
      end
    end)
    |> Concoction.Utils.keys_to_strings()
    |> :erlang.term_to_binary()
  end
end
