defmodule BitPal.Backend.Monero.Wallet do
  alias BitPal.Backend.Monero.WalletRPC

  def start_link(opts) do
    # Start `monero-wallet-rpc`
    WalletRPC.start_link(opts)

    # Generate wallet if it doesn't exist `generate_from_keys`
    # Open wallet `open_wallet`
    # `create_account` 1 if account doesn't exist
  end
end
