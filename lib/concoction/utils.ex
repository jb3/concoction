defmodule Concoction.Utils do
  @moduledoc """
  Various utilities for Concoction.
  """

  @doc """
  Convert all map keys to strings recursively.
  """
  def keys_to_strings(map) do
    Enum.reduce(map, %{}, fn {attr, val}, acc ->
      val = if is_map(val) do
        keys_to_strings(val)
      else
        val
      end

      attr = if is_atom(attr) do
        Atom.to_string(attr)
      else
        attr
      end

      Map.put acc, attr, val
    end)
  end
end
