require 'test_helper'

# start geth: geth --rpcapi "eth,web3" --testnet
# geth attach: geth attach ipc:/Users/u2/Library/Ethereum/testnet/geth.ipc
# open rpc: admin.startRPC("127.0.0.1", 8545, "*", "web3,net,eth")
class ClientTest < Minitest::Test
  def setup
    @client = EthJsonRpc::Client.new
  end

  def test_eth_accounts
    accounts = @client.eth_accounts

    assert accounts.kind_of?(Array)
  end

  def test_eth_coinbase
    account = @client.eth_coinbase

    assert_equal account.size, 42
  end

  def test_eth_mining
    mining = @client.eth_mining

    assert_equal mining, false
  end

  def test_web3_clientVersion
    web3 = @client.web3_clientVersion

    assert_match /Geth/, web3
  end

  def test_web3_sha3
    sha3 = @client.web3_sha3('0x68656c6c6f20776f726c64')

    assert_equal sha3, '0x47173285a8d7341e5e972fc677286384f802f8ef42a5ec5f03bbfa254cb01fad'
  end

  def test_net_version
    version = @client.net_version

    assert_equal version, "2"
  end

  def test_net_listening
    listening = @client.net_listening

    assert_equal listening, true
  end

  def test_net_peerCount
    net_peerCount = @client.net_peerCount

    assert net_peerCount.kind_of?(Integer)
  end

  def test_eth_protocolVersion
    eth_protocolVersion = @client.eth_protocolVersion

    assert eth_protocolVersion.kind_of?(String)
  end

  def test_eth_syncing
    eth_syncing = @client.eth_syncing

    assert eth_syncing.has_key?("currentBlock")
  end

  def test_eth_hashrate
    eth_hashrate = @client.eth_hashrate

    assert_equal eth_hashrate, 0
  end

  def test_eth_gasPrice
    eth_gasPrice = @client.eth_gasPrice

    assert eth_gasPrice.kind_of?(Integer)
  end

  def test_eth_blockNumber
    eth_blockNumber = @client.eth_blockNumber

    assert eth_blockNumber.kind_of?(Integer)
  end

  def test_eth_getBalance
    balance = @client.eth_getBalance('0x21b2b9b4630d600a66cbd45e4dc68368777d5909')

    assert balance.kind_of?(Numeric)
  end

  def test_eth_getStorageAt
    storage = @client.eth_getStorageAt("0x295a70b2de5e3953354a6a8344e616ed314d7251")

    assert storage.start_with?('0x')
  end

  def test_eth_getTransactionCount
    count = @client.eth_getTransactionCount("0x21b2b9b4630d600a66cbd45e4dc68368777d5909")

    assert count.kind_of?(Integer)
  end

  def test_eth_getBlockTransactionCountByHash
    block = @client.eth_getBlockTransactionCountByHash("0xb903239f8543d04b5dc1ba6579132b143087c68db1b2168786408fcbce568238")

    assert_equal block, nil
  end

  def test_eth_getBlockTransactionCountByNumber
    block = @client.eth_getBlockTransactionCountByNumber

    assert block.kind_of?(Integer)
  end

  def test_eth_getCode
    code = @client.eth_getCode('0xa94f5374fce5edbc8e2a8697c15331677e6ebf0b', 2)

    assert_equal code, '0x'
  end

  def test_eth_sign
    # curl http://localhost:8545 -X POST -d '{"jsonrpc":"2.0","method":"eth_sign","params":["0x8a3106a3e50576d4b6794a0e74d3bb5f8c9acaab", "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"],"id":1}'
    # {"jsonrpc":"2.0","id":1,"error":{"code":-32000,"message":"account is locked"}}
    assert_raises StandardError do
      @client.eth_sign('0x21b2b9b4630d600a66cbd45e4dc68368777d5909', '0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470')
    end
  end

  def 
end
