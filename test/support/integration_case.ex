defmodule BitPal.IntegrationCase do
  @moduledoc """
  This module defines the setup for tests requiring
  to the application's backend services, such as currency
  backends or database.
  """

  use ExUnit.CaseTemplate
  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import BitPal.IntegrationCase
      import BitPal.TestHelpers
      import BitPal.IntegrationCase, only: [setup_integration: 0, setup_integration: 1]

      alias BitPal.Addresses
      alias BitPal.BackendManager
      alias BitPal.BackendMock
      alias BitPal.Currencies
      alias BitPal.ExchangeRate
      alias BitPal.InvoiceManager
      alias BitPal.Invoices
      alias BitPal.Repo
      alias BitPal.Transactions
      alias BitPalSchemas.Invoice
    end
  end

  setup tags do
    setup_integration(tags)
  end

  def setup_integration(tags \\ []) do
    start_supervised!({Phoenix.PubSub, name: BitPal.PubSub})
    start_supervised!(BitPal.ProcessRegistry)
    start_supervised!({BitPal.Cache, name: BitPal.RuntimeStorage, clear_interval: :inf})

    setup_db(tags)

    BitPal.Currencies.register!([:XMR, :BCH, :DGC])

    if tags[:backends] do
      setup_backends(tags)
    end

    :ok
  end

  defp setup_db(tags) do
    start_supervised!(BitPal.Repo)
    :ok = Sandbox.checkout(BitPal.Repo)

    unless tags[:async] do
      Sandbox.mode(BitPal.Repo, {:shared, self()})
    end
  end

  defp setup_backends(tags) do
    # Only start backend if explicitly told to
    backend_manager =
      if backends = backends(tags) do
        if !Enum.empty?(backends) do
          start_supervised!({BitPal.BackendManager, backends: backends})
        end
      end

    invoice_manager =
      start_supervised!(
        {BitPal.InvoiceManager, double_spend_timeout: Map.get(tags, :double_spend_timeout, 100)}
      )

    %{
      backend_manager: backend_manager,
      invoice_manager: invoice_manager
    }
  end

  defp backends(%{backends: true}), do: [BitPal.BackendMock]
  defp backends(%{backends: backends}), do: backends
  defp backends(_), do: nil
end
