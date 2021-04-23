import Config

config :bitpal, :monero,
  main_address:
    "496YrjKKenbYS6KCfPabsJ11pTkikW79ZDDrkPDTC79CSTdCoubgh3f5BrupzBvPLWXNjjNsY8smmFDYvgVRQDsmCT5FhCU",
  private_view_key: "805b4f767bdc7774a5c5ae2b3b8981c53646fff952f92de1ff749cf922e26d0f"

case Config.config_env() do
  :dev ->
    config :bitpal,
      backends: [{BitPal.BackendMock, auto: true}]

    config :bitpal, BitPal.ExchangeRate, backends: [BitPal.ExchangeRate.Mock]

  :test ->
    config :bitpal,
      backends: [],
      http_client: BitPal.TestHTTPClient

    config :bitpal, BitPal.ExchangeRate, backends: [BitPal.ExchangeRate.Kraken]

  _ ->
    :ok
end
