use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :proxy, Proxy.Endpoint,
  http: [port: 4002],
  server: false

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :demo, Demo.Endpoint,
  http: [port: 4002],
  server: false

config :bitpal,
  backends: [BitPal.BackendStub]

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :bitpal, BitPal.Repo,
  username: "postgres",
  password: "postgres",
  database: "payments_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :bitpal_web, BitpalWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
