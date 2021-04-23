defmodule BitPal.Backend.Monero do
  use GenServer
  require Logger
  alias BitPal.Backend
  alias BitPal.ExtNotificationHandler
  alias BitPal.Backend.Monero.{DaemonRPC, Wallet}

  @behaviour Backend

  @supervisor MoneroSupervisor

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl Backend
  def register(backend, invoice) do
    GenServer.call(backend, {:register, invoice})
  end

  @impl Backend
  def supported_currencies(_backend) do
    [:xmr]
  end

  @impl Backend
  def configure(_backend, _opts) do
    :ok
  end

  # Server API

  @impl true
  def init(init_args) do
    Logger.info("Starting Monero backend")

    ExtNotificationHandler.subscribe("monero:tx-notify")
    ExtNotificationHandler.subscribe("monero:block-notify")
    ExtNotificationHandler.subscribe("monero:reorg-notify")

    children = [
      DaemonRPC,
      Wallet
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: @supervisor)

    {:ok, init_args}
  end

  @impl true
  def handle_call({:register, invoice}, _from, state) do
    # Generate a new subaddress for the invoice
    # Maybe with `create_address`?
    invoice = %{invoice | address: Wallet.generate_subaddress(invoice)}

    {:reply, invoice, state}
  end

  @impl true
  def handle_info({:notify, "monero:tx-notify", msg}, state) do
    IO.puts("tx seen: #{inspect(msg)}")

    [txid] = msg

    # Lookup tx hash with `get_transfer_by_txid`
    # We could/should check for 0-conf security here
    # Otherwise the subaddress the tx is going to is should be accepted (assuming it's paid in full!)

    address = Wallet.get_subaddress_from_txid(txid)

    {:noreply, state}
  end

  @impl true
  def handle_info({:notify, "monero:block-notify", msg}, state) do
    IO.puts("block seen: #{inspect(msg)}")

    # Check if we have any pending invoice without a confirmation, poll them for info and see if they're conf

    {:noreply, state}
  end

  @impl true
  def handle_info({:notify, "monero:reorg-notify", msg}, state) do
    Logger.warn("reorg detected!: #{inspect(msg)}")

    # Must check if any previously confirmed invoice is affected

    {:noreply, state}
  end

  # Internal impl
end
