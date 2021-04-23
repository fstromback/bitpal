defmodule BitPal.Backend.Monero.WalletRPC do
  use GenServer

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # Server API

  @impl true
  def init(init_args) do
    {:ok, init_args}
  end
end
