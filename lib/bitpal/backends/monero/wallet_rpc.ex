defmodule BitPal.Backend.Monero.WalletRPC do
  use GenServer

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def generate_from_keys(restore_height, filename, address, viewkey, password) do
  end

  def open_wallet(filename, password) do
  end

  def create_account() do
  end

  def get_accounts() do
  end

  @spec create_address(non_neg_integer) :: :ok
  def create_address(account_index) do
    :ok
  end

  @spec get_balance(non_neg_integer, [non_neg_integer]) :: :ok
  def get_balance(account_index, subaddress_indices \\ []) do
    :ok
  end

  # get_transfers, gets a ton of things at the same time
  # also a bunch of other options
  def get_transfers(account_index, subaddress_indices \\ []) do
  end

  def get_transfer_by_txid(txid, account_index) do
  end

  # Server API

  @impl true
  def init(init_args) do
    {:ok, init_args}
  end
end
