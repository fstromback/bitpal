defmodule BitPal.Currencies do
  alias BitPal.Repo
  alias BitPalSchemas.Currency
  alias Ecto.Changeset

  @currencies %{
    BCH: %{name: "Bitcoin Cash", exponent: 8, symbol: "BCH"},
    BTC: %{name: "Bitcoin", exponent: 8, symbol: "BTC"},
    DGC: %{name: "Dogecoin", exponent: 8, symbol: "DGC"},
    XMR: %{name: "Monero", exponent: 12, symbol: "XMR"}
  }

  @spec get!(Currency.id()) :: Currency.t()
  def get!(id) do
    Repo.get!(Currency, normalize(id))
  end

  @spec register!([Currency.id()] | Currency.id()) :: :ok
  def register!(ids) when is_list(ids) do
    Enum.each(ids, &register!/1)
  end

  def register!(id) do
    Repo.insert!(%Currency{id: normalize(id)}, on_conflict: :nothing)
  end

  @spec set_height!(Currency.id(), non_neg_integer) :: :ok
  def set_height!(id, height) do
    Repo.update!(Changeset.change(%Currency{id: normalize(id)}, block_height: height))
  end

  @spec normalize(Currency.id()) :: String.t()
  def normalize(id) when is_binary(id) do
    id |> String.upcase()
  end

  def normalize(id) when is_atom(id) do
    Atom.to_string(id) |> String.upcase()
  end

  def configure_money do
    # Configure here because we want to configure :money, even when run as a library.
    # Should probably merge with existing config...
    Application.put_env(:money, :custom_currencies, @currencies)
  end
end
