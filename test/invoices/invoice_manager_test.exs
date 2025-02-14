defmodule InvoiceManagerTest do
  use BitPal.IntegrationCase
  alias BitPal.Currencies
  alias BitPal.ExchangeRate
  alias BitPal.InvoiceManager

  @tag backends: true
  test "initialize" do
    Currencies.register!(:BCH)

    assert {:ok, inv1} =
             Invoices.register(%{
               amount: Money.parse!(2.5, "BCH"),
               exchange_rate: ExchangeRate.new!(Decimal.from_float(1.1), {"BCH", "USD"})
             })

    assert {:ok, inv1_id} = InvoiceManager.track(inv1)

    assert {:ok, inv2} =
             Invoices.register(%{
               amount: Money.parse!(5.2, "BCH"),
               exchange_rate: ExchangeRate.new!(Decimal.from_float(1.1), {"BCH", "USD"})
             })

    assert {:ok, inv2_id} = InvoiceManager.track(inv2)

    assert inv1_id != inv2_id
    assert {:ok, inv1_pid} = InvoiceManager.get_handler(inv1_id)
    assert {:ok, inv2_pid} = InvoiceManager.get_handler(inv2_id)
    assert inv1_pid != inv2_pid
    assert InvoiceManager.count_children() == 2

    assert_shutdown(inv2_pid)

    assert InvoiceManager.count_children() == 2
  end
end
