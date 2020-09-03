defmodule Concoction.API.Gateway do
  @moduledoc """
  API utilities for fetching information on the Discord Gateway.
  """

  alias Concoction.HTTP

  @doc """
  Fetch the Gateway without authentication, not returning any shard information.
  """
  @spec get_gateway() :: {:ok, String.t()} | {:error, map()}
  def get_gateway do
    case HTTP.request(:get, "/gateway") do
      {:ok, resp} -> {:ok, resp["url"]}
      {:error, resp} -> {:error, resp}
    end
  end

  @doc """
  Fetch the Gateway with authentication, returning the gateway URL and shard count.
  """
  @spec get_gateway_bot() :: {:ok, String.t(), integer()} | {:error, map()}
  def get_gateway_bot do
    case HTTP.request(:get, "/gateway/bot") do
      {:ok, resp} -> {:ok, resp["url"], resp["shards"]}
      {:error, resp} -> {:error, resp}
    end
  end
end
