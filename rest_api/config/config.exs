# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :rest_api, RestApiWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "6FTN0B9V6SqJfGIEgYCl2HJzrwStTyj6iZXwKM56sXHIl4MNSo2BC3F094SqI0c7",
  render_errors: [view: RestApiWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: RestApi.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  compile_time_purge_matching: [
      [module: DataPointsStore, level_lower_than: :error],
      [module: DataPoints, level_lower_than: :info],
    ],
    metadata: [:user_id]

  config :logger,
  backends: [:console],
  compile_time_purge_matching: [
#    [application: :data_points],
    [module: DataPointsStore, level_lower_than: :error],
    [module: DataPoints, level_lower_than: :info],
 #   [module: DataPoints, function: "foo/3", level_lower_than: :debug]
  ]


# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
