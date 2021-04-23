defmodule BitPal.Backend.Monero.Wallet do
  alias BitPal.Backend.Monero.DaemonRPC
  alias BitPal.Backend.Monero.WalletRPC

  # FIXME configurable what account we should pass our payments to
  @account 1

  @password "some-cool-password"

  # FIXME state we need to hold in a database:
  # account_index
  # unused subaddresses
  # current subaddress index

  def start_link(opts) do
    # Start `monero-wallet-rpc`
    WalletRPC.start_link(opts)

    init_wallet(
      main_address: Application.fetch_env!(:bitpal, :monero)[:main_address],
      private_view_key: Application.fetch_env!(:bitpal, :monero)[:private_view_key]
    )
  end

  defp init_wallet(main_address: main_address, private_view_key: private_view_key) do
    file = Application.get_env(:bitpal, :monero)[:wallet_file]

    if !File.exists?(file) do
      generate_wallet(
        filename: file,
        main_address: main_address,
        private_view_key: private_view_key
      )
    end

    WalletRPC.open_wallet(file, @password)

    if !account_exists?(@account) do
      WalletRPC.create_account()
    end
  end

  defp generate_wallet(
         filename: filename,
         main_address: main_address,
         private_view_key: private_view_key
       ) do
    current_height = DaemonRPC.get_block_count()

    WalletRPC.generate_from_keys(
      current_height,
      filename,
      main_address,
      private_view_key,
      @password
    )
  end

  defp account_exists?(account) do
  end
end
