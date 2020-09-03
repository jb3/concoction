defmodule Concoction.HTTP do
  @moduledoc """
  Utilities for handling commmunication with the Discord API.

  This will handle ratelimits, authorization & user agent headers.
  """

  @version Concoction.MixProject.application()[:version]

  @base_url "https://discord.com/api/v8/"

  require Logger

  @spec init :: :ok
  @doc """
  Initialize the tables required in ETS for the HTTP client. This storage handles information on ratelimit buckets.
  """
  def init() do
    :ets.new(:buckets, [:set, :public, :named_table])

    :ok
  end

  @spec get_bucket(String.t(), list()) :: String.t()
  defp get_bucket(path, params) do
    "#{params[:guild_id]}:#{params[:channel_id]}:#{path}"
  end

  @spec maybe_int?(String.t()) :: integer() | nil
  def maybe_int?(integer) do
    if integer == nil do
      nil
    else
      Integer.parse(integer)
      |> elem(0)
    end
  end

  @spec maybe_float?(String.t()) :: float() | nil
  def maybe_float?(float) do
    if float == nil do
      nil
    else
      Float.parse(float)
      |> elem(0)
    end
  end

  @typedoc """
  The HTTP method used to make the request.
  """
  @type method ::
    :get
    | :post
    | :put
    | :patch
    | :delete

  @spec process_response(String.t(), Tesla.Env.t()) :: {:ok | :error, map() | list() | nil}
  defp process_response(path, response) do
    code = response.status

    Logger.debug "Processing #{code} response for #{path}"

    status = cond do
      code == nil -> :error
      code in 200..399 -> :ok
      code in 400..599 -> :error
    end

    bucket = get_bucket(path, response.opts[:path_params])

    :ets.insert(:buckets, {
      bucket,
      Tesla.get_header(response, "x-ratelimit-remaining") |> maybe_int?,
      Tesla.get_header(response, "x-ratelimit-reset") |> maybe_float?
    })

    {status, response.body}
  end

  @spec ratelimit_remaining(binary, [any]) :: integer()
  def ratelimit_remaining(url, params) do
    bucket = get_bucket(url, params)

    case :ets.lookup(:buckets, bucket) do
      [ratelimit] ->
        # Check if we have any requests remaining
        case elem(ratelimit, 1) do
          # Quota used
          0 ->
            remaining = Float.ceil(elem(ratelimit, 2)) - DateTime.to_unix(DateTime.utc_now()) |> trunc
            cond do
              remaining <= 0 -> 0
              true -> remaining * 1000
            end
          _quota_left ->
            0
        end
      [] -> 0
    end
  end

  @doc """
  Make a request to the Discord API.

  When a method is GET, the data parameter is passed as query-string data.

  For other requests it is passed as the post body.

  If a ratelimit is hit this function will block until the ratelimit is over.

  Returns the status code and JSON body or nil for requests with no response.
  """
  @spec request(method(), String.t(), map()) :: list() | {:ok | :error, map() | list() | nil}
  def request(method, path, data \\ %{}, params \\ []) do
    opts = [
      method: method,
      url: path,
      query: data,
      opts: [
        path_params: params
      ]
    ]

    opts = if method == :get do
      Keyword.put opts, :query, data
    else
      Keyword.put opts, :body, data
    end

    case ratelimit_remaining(path, params) do
      0 -> {:ok, resp} = Tesla.request(construct_client(), opts)

            process_response(path, resp)
      time ->
        Logger.debug "Ratelimited on bucket #{get_bucket(path, params)}, trying again in #{time / 1000} seconds"
        Process.sleep(time)
        request(method, path, data, params)
    end
  end

  @spec construct_client() :: Tesla.Client.t()
  defp construct_client() do
    headers = [
      {"Authorization", "Bot " <> Application.fetch_env!(:concoction, :token)},
      {"User-Agent", "DiscordBot (https://github.com/jb3/concoction, #{@version})"}
    ]

    middleware = [
      {Tesla.Middleware.BaseUrl, Application.get_env(:concoction, :base_url, @base_url)},
      Tesla.Middleware.PathParams,
      Tesla.Middleware.JSON,
      Tesla.Middleware.Compression,
      {Tesla.Middleware.Headers, headers}
    ]

    Tesla.client(middleware)
  end
end
