# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :survey, Survey.Endpoint,
  url: [host: "localhost"],
  root: Path.dirname(__DIR__),
  secret_key_base: "W/ssZ9qGwluI9hS4j6kDHYadraiySvs197EAGiKMpsE49X6V6NEEDr/RhIuwevyy",
  debug_errors: false,
  pubsub: [name: Survey.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# all numbers are seconds
config :jobs,
  groups: %{},
  default: %{
    max_tries: 5,
    worker_maxtime: 60,
    wait_try_again: 1200,
    strategy: :backoff
  }

config :etherpad_week,
  current: 5

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
