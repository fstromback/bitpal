defmodule BitPal.Blocks do
  alias BitPal.BlockchainEvents
  alias BitPal.Currencies
  alias BitPalSchemas.Currency

  @type currency_id :: Currency.id()
  @type height :: non_neg_integer()

  @spec fetch_block_height!(currency_id) :: height
  def fetch_block_height!(currency_id) do
    Currencies.get!(currency_id).block_height
  end

  @spec new_block(currency_id, height) :: :ok | {:error, term}
  def new_block(currency_id, height) do
    Currencies.set_height!(currency_id, height)
    BlockchainEvents.broadcast(currency_id, {:new_block, currency_id, height})
  end

  @spec set_block_height(currency_id, height) :: :ok | {:error, term}
  def set_block_height(currency_id, height) do
    Currencies.set_height!(currency_id, height)
    BlockchainEvents.broadcast(currency_id, {:set_block_height, currency_id, height})
  end

  @spec block_reversed(currency_id, height) :: :ok | {:error, term}
  def block_reversed(currency_id, height) do
    Currencies.set_height!(currency_id, height)
    BlockchainEvents.broadcast(currency_id, {:block_reversed, currency_id, height})
  end
end
