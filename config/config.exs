import Mix.Config

if File.regular?("config/dev.exs") do
  import_config "dev.exs"
end

if System.get_env("CI") do
  import_config "ci.exs"
end

config :tesla, adapter: Tesla.Adapter.Gun
