require 'json'
require 'net/http'
require 'digest/sha3'
require 'rlp'
require 'eth_json_rpc/abi'
require "eth_json_rpc/utils"
require 'eth_json_rpc/constants'
require 'byebug'

module EthJsonRpc
  class Client
    include Constants
    include Utils
    attr_accessor :host, :port, :tls

    def initialize(host = 'localhost', port = GETH_DEFAULT_RPC_PORT, tls = false)
      self.host = host
      self.port = port
      self.tls  = tls
    end

################################################################################
# high-level methods
################################################################################

    ##
    # Send wei from one address to another
    def transfer(from_, to, amount)
      eth_sendTransaction(from: from_, to: to, value: amount)
    end

    ##
    # Create a contract on the blockchain from compiled EVM code. Returns the
    # transaction hash.
    def create_contract(from_, code, gas, sig, args)
      from_ = from_ or self.eth_coinbase
      if sig and args
        i = sig.index('(') + 1
        j = sig.index(')')
        types = sig[i...j].split(',')
        encoded_params = encode_abi(types, args)
        code += encoded_params.encode('hex')
      end
      eth_sendTransaction(from: from_, gas: gas, data: code)
    end

    ##
    # Get the address for a contract from the transaction that created it
    def get_contract_address(tx)
      receipt = self.eth_getTransactionReceipt(tx)
      return receipt['contractAddress']
    end

    ##
    # Call a contract function on the RPC server, without sending a
    # transaction (useful for reading data)
    def call(address, sig, args, result_types)
      data = self._encode_function(sig, args)
      data_hex = encode_to_hex(data)
      response = eth_call(to: address, data: data_hex)
      return decode_abi(result_types, encode_to_hex(response[2..-1]))
    end

    ##
    # Call a contract function by sending a transaction (useful for storing
    # data)
    def call_with_transaction(from_, address, sig, args, gas = nil, gasPrice = nil, value = nil)
      gas = gas or DEFAULT_GAS_PER_TX
      gasPrice = gasPrice or DEFAULT_GAS_PRICE
      data = self._encode_function(sig, args)
      data_hex = encode_to_hex(data)
      eth_sendTransaction(from: from_,
                          to: address, data: data_hex, gas: gas,
                          gasPrice: gasPrice, value: value)
    end
################################################################################
# JSON-RPC methods
################################################################################

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#web3_clientversion
    def web3_clientVersion
      _call('web3_clientVersion')
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#web3_sha3
    # TODO: data is array and the item can be str, hex or integer
    # as https://github.com/ethereumjs/ethereumjs-abi
    # TODO: fix python version
    def web3_sha3(data)
      _call('web3_sha3', [data])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#net_version
    def net_version
      _call('net_version')
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#net_listening
    def net_listening
      _call('net_listening')
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#net_peercount
    def net_peerCount
      hex_to_dec(_call('net_peerCount'))
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_protocolversion
    def eth_protocolVersion
      _call('eth_protocolVersion')
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_syncing
    def eth_syncing
      _call('eth_syncing')
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_coinbase
    def eth_coinbase
      _call('eth_coinbase')
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_mining
    def eth_mining
      _call('eth_mining')
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_hashrate
    def eth_hashrate
      hex_to_dec(_call('eth_hashrate'))
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_gasprice
    def eth_gasPrice
      hex_to_dec(_call('eth_gasPrice'))
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_accounts
    def eth_accounts
      _call('eth_accounts')
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_blocknumber
    def eth_blockNumber
      hex_to_dec(_call('eth_blockNumber'))
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_getbalance
    def eth_getBalance(address, block = BLOCK_TAG_LATEST)
      address = address or self.eth_coinbase
      block = validate_block(block)
      hex_to_dec(_call('eth_getBalance', [address, block]))
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_getstorageat
    def eth_getStorageAt(address, position = 0, block=BLOCK_TAG_LATEST)
      block = validate_block(block)
      _call('eth_getStorageAt', [address, int_to_hex(position), block])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_gettransactioncount
    def eth_getTransactionCount(address, block=BLOCK_TAG_LATEST)
      block = validate_block(block)
      hex_to_dec(_call('eth_getTransactionCount', [address, block]))
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_getblocktransactioncountbyhash
    def eth_getBlockTransactionCountByHash(block_hash)
      hash = _call('eth_getBlockTransactionCountByHash', [block_hash])
      hex_to_dec(hash) if hash
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_getblocktransactioncountbynumber
    def eth_getBlockTransactionCountByNumber(block = BLOCK_TAG_LATEST)
      block = validate_block(block)
      hex_to_dec(_call('eth_getBlockTransactionCountByNumber', [block]))
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_getunclecountbyblockhash
    def eth_getUncleCountByBlockHash(block_hash)
      hex_to_dec(_call('eth_getUncleCountByBlockHash', [block_hash]))
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_getunclecountbyblocknumber
    def eth_getUncleCountByBlockNumber(block = BLOCK_TAG_LATEST)
      block = validate_block(block)
      hex_to_dec(_call('eth_getUncleCountByBlockNumber', [block]))
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_getcode
    def eth_getCode(address, default_block = BLOCK_TAG_LATEST)
      case default_block
      when String
        raise ArgumentError unless BLOCK_TAGS.include?(default_block)
      when Integer
      else
        raise ArgumentError
      end
      _call('eth_getCode', [address, default_block])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign
    def eth_sign(address, data)
      _call('eth_sign', [address, data])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sendtransaction
    def eth_sendTransaction(data = {})
      params = {}
      params['from'] = data[:from] or self.eth_coinbase
      params['to'] = data[:to] if data[:to]
      params['gas'] = int_to_hex(data[:gas]) if data[:gas]
      params['gasPrice'] = int_to_hex(data[:gasPrice]) if data[:gasPrice]
      params['value'] = int_to_hex(data[:value]) if data[:value]
      params['data'] = data[:data] if data[:data]
      params['nonce'] = int_to_hex(data[:nonce]) if data[:nonce]
      _call('eth_sendTransaction', [params])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sendrawtransaction
    def eth_sendRawTransaction(data)
        _call('eth_sendRawTransaction', [data])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_call
    def eth_call(data = {})
      default_block = data[:default_block]
      if default_block.is_a?(String) && !BLOCK_TAGS.include?(default_block)
        raise ArgumentError
      end
      default_block = BLOCK_TAG_LATEST unless default_block
      obj = {}
      obj['to'] = data[:to]
      obj['from'] = data[:from] if data[:from]
      obj['gas'] = int_to_hex(data[:gas]) if data[:gas]
      obj['gasPrice'] = int_to_hex(data[:gasPrice]) if data[:gasPrice]
      obj['value'] = data[:value] if data[:value]
      obj['data'] = data[:data] if data[:data]
      _call('eth_call', [obj, default_block])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_estimategas
    def eth_estimateGas(data = {})
      default_block = data[:default_block]
      if default_block.is_a?(String) && !BLOCK_TAGS.include?(default_block)
        raise ArgumentError
      end
      default_block = BLOCK_TAG_LATEST unless default_block
      obj = {}
      obj['to'] = data[:to]
      obj['from'] = data[:from] if data[:from]
      obj['gas'] = int_to_hex(data[:gas]) if data[:gas]
      obj['gasPrice'] = int_to_hex(data[:gasPrice]) if data[:gasPrice]
      obj['value'] = data[:value] if data[:value]
      obj['data'] = data[:data] if data[:data]
      _call('eth_estimateGas', [obj, default_block])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_getblockbyhash
    def eth_getBlockByHash(block_hash, tx_objects = true)
      _call('eth_getBlockByHash', [block_hash, tx_objects])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_getblockbynumber
    def eth_getBlockByNumber(block = BLOCK_TAG_LATEST, tx_objects = true)
      block = validate_block(block)
      _call('eth_getBlockByNumber', [block, tx_objects])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_gettransactionbyhash
    def eth_getTransactionByHash(tx_hash)
      _call('eth_getTransactionByHash', [tx_hash])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_gettransactionbyblockhashandindex
    def eth_getTransactionByBlockHashAndIndex(block_hash, index = 0)
      _call('eth_getTransactionByBlockHashAndIndex', [block_hash, int_to_hex(index)])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_gettransactionbyblocknumberandindex
    def eth_getTransactionByBlockNumberAndIndex(block = BLOCK_TAG_LATEST, index=0)
      block = validate_block(block)
      _call('eth_getTransactionByBlockNumberAndIndex', [block, int_to_hex(index)])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_gettransactionreceipt
    def eth_getTransactionReceipt(tx_hash)
      _call('eth_getTransactionReceipt', [tx_hash])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_getunclebyblockhashandindex
    def eth_getUncleByBlockHashAndIndex(block_hash, index = 0)
      _call('eth_getUncleByBlockHashAndIndex', [block_hash, int_to_hex(index)])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_getunclebyblocknumberandindex
    def eth_getUncleByBlockNumberAndIndex(block = BLOCK_TAG_LATEST, index = 0)
      block = validate_block(block)
      _call('eth_getUncleByBlockNumberAndIndex', [block, int_to_hex(index)])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_getcompilers
    def eth_getCompilers
      _call('eth_getCompilers')
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_compilesolidity
    def eth_compileSolidity(code)
      _call('eth_compileSolidity', [code])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_compilelll
    def eth_compileLLL(code)
      _call('eth_compileLLL', [code])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_compileserpent
    def eth_compileSerpent(code)
      _call('eth_compileSerpent', [code])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_newfilter
    def eth_newFilter(from_block=BLOCK_TAG_LATEST, to_block=BLOCK_TAG_LATEST, address=None, topics=None)
      _filter = {
          'fromBlock': from_block,
          'toBlock':   to_block,
          'address':   address,
          'topics':    topics,
      }
      _call('eth_newFilter', [_filter])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_newblockfilter
    def eth_newBlockFilter(default_block=BLOCK_TAG_LATEST)
      _call('eth_newBlockFilter', [default_block])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_newpendingtransactionfilter
    def eth_newPendingTransactionFilter
      hex_to_dec(_call('eth_newPendingTransactionFilter'))
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_uninstallfilter
    def eth_uninstallFilter(filter_id)
      _call('eth_uninstallFilter', [filter_id])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_getfilterchanges
    def eth_getFilterChanges(filter_id)
      _call('eth_getFilterChanges', [filter_id])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_getfilterlogs
    def eth_getFilterLogs(filter_id)
      _call('eth_getFilterLogs', [filter_id])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_getlogs
    def eth_getLogs(filter_object)
      _call('eth_getLogs', [filter_object])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_getwork
    def eth_getWork
      _call('eth_getWork')
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_submitwork
    def eth_submitWork(nonce, header, mix_digest)
      _call('eth_submitWork', [nonce, header, mix_digest])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_submithashrate
    def eth_submitHashrate(hash_rate, client_id)
      _call('eth_submitHashrate', [int_to_hex(hash_rate), client_id])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#db_putstring
    def db_putString(db_name, key, value)
      $stderr.puts "Note this function is deprecated and will be removed in the future."
      _call('db_putString', [db_name, key, value])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#db_getstring
    def db_getString(db_name, key)
      $stderr.puts "Note this function is deprecated and will be removed in the future."
      _call('db_getString', [db_name, key])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#db_puthex
    def db_putHex(db_name, key, value)
      if not value.startswith('0x')
        value = '0x{}'.format(value)
      end
      $stderr.puts "Note this function is deprecated and will be removed in the future."
      _call('db_putHex', [db_name, key, value])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#db_gethex
    def db_getHex(db_name, key)
      $stderr.puts "Note this function is deprecated and will be removed in the future."
      _call('db_getHex', [db_name, key])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#shh_version
    def shh_version
      _call('shh_version')
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#shh_post
    def shh_post(topics, payload, priority, ttl, from_= nil, to = nil)
      whisper_object = {
        'from':     from_,
        'to':       to,
        'topics':   topics,
        'payload':  payload,
        'priority': hex(priority),
        'ttl':      hex(ttl),
      }
      _call('shh_post', [whisper_object])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#shh_newidentity
    def shh_newIdentity
      _call('shh_newIdentity')
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#shh_hasidentity
    def shh_hasIdentity(address)
      _call('shh_hasIdentity', [address])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#shh_newgroup
    def shh_newGroup
      _call('shh_newGroup')
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#shh_addtogroup
    def shh_addToGroup
      _call('shh_addToGroup')
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#shh_newfilter
    def shh_newFilter(to, topics)
      _filter = {
        'to':     to,
        'topics': topics
      }
      _call('shh_newFilter', [_filter])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#shh_uninstallfilter
    def shh_uninstallFilter(filter_id)
      _call('shh_uninstallFilter', [filter_id])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#shh_getfilterchanges
    def shh_getFilterChanges(filter_id)
      _call('shh_getFilterChanges', [filter_id])
    end

    ##
    # @see https://github.com/ethereum/wiki/wiki/JSON-RPC#shh_getmessages
    def shh_getMessages(filter_id)
      _call('shh_getMessages', [filter_id])
    end

    private

    def _call(method, params = [], _id = 1)
      data = {
        'jsonrpc': '2.0',
        'method':  method,
        'params':  params,
        'id':      _id,
      }

      begin
        uri = URI("#{tls ? 'https' : 'http'}://#{host}:#{port}")
        http = Net::HTTP.start(host, port, use_ssl: tls)
        r = http.post uri, JSON.dump(data)
      rescue Net::HTTPError
        raise ConnectionError
      end

      if r.code.to_i / 100 != 2
        raise BadStatusCodeError.new(r.code)
      end

      begin
        response = JSON.parse(r.body)
      rescue
        BadJsonError.new(r.body)
      end

      if response.has_key?('result')
        response['result']
      # TODO: fixed python version
      elsif response.has_key?('error')
        raise StandardError.new(response['error'])
      else
        raise BadResponseError.new(response)
      end
    end

    def encode_function(signature, param_values)
      prefix = RLP::Utils.big_endian_to_int(EthJsonRpc::Utils.keccak256(signature)[4..-1])

      if signature.index('(').nil?
        raise RuntimeError.new('Invalid function signature. Missing "(" and/or ")"...')
      end
      if signature.index(')') - signature.index('(') == 1
        return Rlp::Utils.encode_int(prefix)
      end
      i = signature.index('(') + 1
      j = signature.index(')')
      types = signature[i...j].split(',')
      encoded_params = EthJsonRpc::ABI.encode_abi(types, param_values)
      return Rlp::Utils.zpad(Rlp::Utils.encode_int(prefix), 4) + encoded_params
    end
  end
end
