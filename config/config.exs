import Mix.Config

if File.regular?("config/dev.exs") do
  import_config "dev.exs"
end

config :tesla, adapter: Tesla.Adapter.Gun
