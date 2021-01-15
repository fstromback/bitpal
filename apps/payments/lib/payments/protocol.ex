defmodule Payments.Protocol do
  use Bitwise

  # Tags used in the header
  @header_end 0
  @header_serviceId 1
  @header_messageId 2
  @header_sequenceStart 3
  @header_lastInSequence 4
  @header_ping 5
  @header_pong 6

  # Service names
  @service_api 0
  @service_blockchain 1
  @service_livetransactions 2
  @service_util 3
  @service_test 4
  @service_addressmonitor 17
  @service_blocknotification 18
  @service_indexer 19
  @service_system 126

  # dummy function to disable warnings...
  def dummy() do
    [
      @header_end,
      @header_serviceId,
      @header_messageId,
      @header_sequenceStart,
      @header_lastInSequence,
      @header_ping,
      @header_pong,
      @service_api,
      @service_blockchain,
      @service_livetransactions,
      @service_util,
      @service_test,
      @service_addressmonitor,
      @service_blocknotification,
      @service_indexer,
      @service_system
    ]
  end

  # Helper to create a header.
  defp header(service, message) do
    [{@header_serviceId, service}, {@header_messageId, message}, {@header_end, true}]
  end

  # Extract the header information.
  # Returns { service-id, message-id, message }
  defp parse_header(message) do
    [{@header_serviceId, sid}, {@header_messageId, mid}, {@header_end, _} | rest] = message
    {sid, mid, rest}
  end

  # Helper to extract a particular key from a message
  defp get_key(key, body) do
    case body do
      [{^key, v} | _rest] ->
        v

      [{_, _} | rest] ->
        get_key(key, rest)
    end
  end

  # Helper to get a number of keys at the same time. This is not very efficient...
  # 'keys' is a keyval list, returns a map.
  defp get_keys(keys, body) do
    case keys do
      [{name, first} | rest] ->
        Map.put(get_keys(rest, body), name, get_key(first, body))

      [] ->
        %{}
    end
  end

  # Like get_key, but returns nil if the key is not found.
  defp get_key_opt(key, body) do
    case body do
      [{^key, v} | _rest] ->
        v

      [{_, _} | rest] ->
        get_key_opt(key, rest)

      [] ->
        nil
    end
  end


  # Same as get_keys, but ignores missing keys.
  defp get_keys_opt(keys, body) do
    case keys do
      [{name, first} | rest] ->
        val = get_key_opt(first, body)
        k = get_keys_opt(rest, body)
        if val != nil do
          Map.put(k, name, val)
        else
          k
        end

      [] ->
        %{}
    end
  end

  # Helper to send
  defp send_msg(c, msg) do
    Payments.Connection.send(c, msg)
  end

  # Helper to get a parsed message. Returns {sid, mid, [message...]}
  defp get_message(c) do
    parse_header(Payments.Connection.recv(c))
  end

  # Send a version request message. Returns a string.
  def send_version(c) do
    send_msg(c, header(0, 0))
  end

  # Ask for blockchain info.
  def send_blockchain_info(c) do
    send_msg(c, header(@service_blockchain, 0))
  end

  # Subscribe to get notified of blocks.
  def send_block_subscribe(c) do
    send_msg(c, header(@service_blocknotification, 0))
  end

  # Unsubscribe to get notified of blocks.
  def send_block_unsubscribe(c) do
    send_msg(c, header(@service_blocknotification, 2))
  end

  # List available indexers.
  def send_find_avail_indexers(c) do
    send_msg(c, header(@service_indexer, 0))
  end

  # Find a transaction.
  def send_find_transaction(c, bytes) do
    send_msg(c, header(@service_indexer, 2) ++ [{4, bytes}])
  end

  # Structure for received message.
  defmodule Message do
    defstruct type: nil, data: %{}
  end

  # Helper to create messages
  def make_msg(type, keys, body) do
    %Message{type: type, data: get_keys(keys, body)}
  end

  # Helper to create a message. Does not care if some key is missing.
  def make_msg_opt(type, keys, body) do
    %Message{type: type, data: get_keys_opt(keys, body)}
  end

  # Receive some message (blocking)
  def recv(c) do
    msg = get_message(c)

    case msg do
      {@service_api, 1, body} ->
        # Version message
        make_msg(:version, [version: 1], body)

      {@service_blockchain, 1, body} ->
        # Reply from "blockchain info"
        make_msg(
          :version,
          [
            difficulty: 64,
            medianTime: 65,
            chainWork: 66,
            chain: 67,
            blocks: 68,
            headers: 69,
            bestBlockHash: 70,
            verificationProgress: 71
          ],
          body
        )

      {@service_blocknotification, 4, body} ->
        # Notified of a block
        make_msg(:newBlock, [blockHash: 5, blockHeight: 7], body)

      {@service_indexer, 1, body} ->
        # Indexer reply to what it is indexing.
        make_msg_opt(:availableIndexers, [address: 21, transaction: 22, spentOutput: 23], body)

      {@service_indexer, 3, body} ->
        # Indexer reply to "find transaction"
        make_msg(:transaction, [height: 7, offsetInBlock: 8], body)
        
    end
  end
end
