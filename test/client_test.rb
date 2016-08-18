require 'test_helper'

# start geth: geth --rpcapi "eth,web3"
# geth attach: geth attach
# open rpc: admin.startRPC("127.0.0.1", 8545, "*", "web3,net,eth")
class ClientTest < Minitest::Test
  include EthJsonRpc::Constants
  def setup
    @client = EthJsonRpc::Client.new
  end

  def test_eth_accounts
    accounts = @client.eth_accounts

    assert accounts.kind_of?(Array)
  end

  def test_eth_coinbase
    account = @client.eth_coinbase

    assert_equal 42, account.size
  end

  def test_eth_mining
    mining = @client.eth_mining

    assert_equal false, mining
  end

  def test_web3_clientVersion
    web3 = @client.web3_clientVersion

    assert_match /Geth/, web3
  end

  def test_web3_sha3
    sha3 = @client.web3_sha3('0x68656c6c6f20776f726c64')

    assert_equal '0x47173285a8d7341e5e972fc677286384f802f8ef42a5ec5f03bbfa254cb01fad', sha3
  end

  def test_net_version
    version = @client.net_version

    assert_equal "1", version
  end

  def test_net_listening
    listening = @client.net_listening

    assert_equal true, listening
  end

  def test_net_peerCount
    net_peerCount = @client.net_peerCount

    assert net_peerCount.kind_of?(Integer)
  end

  def test_eth_protocolVersion
    eth_protocolVersion = @client.eth_protocolVersion

    assert eth_protocolVersion.kind_of?(String)
  end

  def test_eth_hashrate
    eth_hashrate = @client.eth_hashrate

    assert_equal 0, eth_hashrate
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
    balance = @client.eth_getBalance('0xb64c196e007632caea083f50a97660f9bf083d20')

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

    assert_equal nil, block
  end

  def test_eth_getBlockTransactionCountByNumber
    block = @client.eth_getBlockTransactionCountByNumber

    assert block.kind_of?(Integer)
  end

  def test_eth_sign
    # curl http://localhost:8545 -X POST -d '{"jsonrpc":"2.0","method":"eth_sign","params":["0x8a3106a3e50576d4b6794a0e74d3bb5f8c9acaab", "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"],"id":1}'
    # {"jsonrpc":"2.0","id":1,"error":{"code":-32000,"message":"account is locked"}}
    exception = assert_raises StandardError do
      @client.eth_sign('0xb64c196e007632caea083f50a97660f9bf083d20', '0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470')
    end

    assert_equal({"code"=>-32000, "message"=>"account is locked"}.to_s, exception.message)
  end

  def test_eth_sendTransaction
    params = {
      from: "0xb64c196e007632caea083f50a97660f9bf083d20",
      to: "0xd46e8dd67c5d32be8058bb8eb970870f07244567",
      gas: 30400,
      gasPrice: 10000000000000,
      value: 2441406250
    }

    exception = assert_raises StandardError do
      @client.eth_sendTransaction(params)
    end

    assert_equal({"code"=>-32000, "message"=>"account is locked"}.to_s, exception.message)
  end

  def test_eth_sendRawTransaction
    data = "0xd46e8dd67c5d32be8d46e8dd67c5d32be8058bb8eb970870f072445675058bb8eb970870f072445675"

    exception = assert_raises StandardError do
      @client.eth_sendRawTransaction(data)
    end

    assert_equal({"code"=>-32000, "message"=>"rlp: element is larger than containing list"}.to_s, exception.message)
  end

  def test_eth_call
    params = {
      from: "0xb64c196e007632caea083f50a97660f9bf083d20",
      to: "0xd46e8dd67c5d32be8058bb8eb970870f07244567",
      gas: 30400,
      gasPrice: 10000000000000,
      value: 2441406250
    }

    r = @client.eth_call(params)

    assert_equal '0x', r
  end

  def test_eth_estimateGas
    params = {
      from: "0xb64c196e007632caea083f50a97660f9bf083d20",
      to: "0xd46e8dd67c5d32be8058bb8eb970870f07244567",
      gas: 30400,
      gasPrice: 10000000000000,
      value: 2441406250,
      data: "0xd46e8dd67c5d32be8d46e8dd67c5d32be8058bb8eb970870f072445675058bb8eb970870f072445675"
    }

    exception = assert_raises StandardError do
      @client.eth_estimateGas(params)
    end

    assert_equal({"code"=>-32602, "message"=>"too many params, want 1 got 2"}.to_s, exception.message)
  end

  # http://etherscan.io/block/1093000
  def test_eth_getBlockByHash
    r = @client.eth_getBlockByHash('0xc96d6ff0548bdd9f11a42916a2b03b19db21ae143d8b139df931d001fd59babc')

    assert_equal "0xe4f9709da6b", r["difficulty"]
  end

  # http://etherscan.io/block/1093000
  def test_eth_getBlockByNumber
    r = @client.eth_getBlockByNumber(1093000)

    assert_equal "0xe4f9709da6b", r["difficulty"]
  end

  # http://etherscan.io/tx/0x8ac3590621f25874830436111622ad1e708255cdb4c9d32e89112538488c61a8
  def test_eth_getTransactionByHash
    r = @client.eth_getTransactionByHash('0x8ac3590621f25874830436111622ad1e708255cdb4c9d32e89112538488c61a8')

    assert_equal "0x8ac3590621f25874830436111622ad1e708255cdb4c9d32e89112538488c61a8", r["hash"]
  end

  # http://etherscan.io/tx/0xb9ecd9de745a75645ce7087f8f51618303039d213778c1ae80547c8a094b66be
  def test_eth_getTransactionByBlockHashAndIndex
    r = @client.eth_getTransactionByBlockHashAndIndex('0xc96d6ff0548bdd9f11a42916a2b03b19db21ae143d8b139df931d001fd59babc', 1)

    assert_equal "0xb9ecd9de745a75645ce7087f8f51618303039d213778c1ae80547c8a094b66be", r["hash"]
  end

  # http://etherscan.io/tx/0xb9ecd9de745a75645ce7087f8f51618303039d213778c1ae80547c8a094b66be
  def test_eth_getTransactionByBlockNumberAndIndex
    r = @client.eth_getTransactionByBlockNumberAndIndex(1093000, 1)

    assert_equal "0xb9ecd9de745a75645ce7087f8f51618303039d213778c1ae80547c8a094b66be", r["hash"]
  end

  def test_transfer
    exception = assert_raises StandardError do
      @client.transfer('0x319109cc083a381a64c40546c92358398b82d97f', '0xE82D5B10ad98d34dF448b07a5a62C1aFfBEf758F', 100000000000000000000)
    end

    assert_equal({"code"=>-32000, "message"=>"account is locked"}.to_s, exception.message)
  end

  def test_get_contract_address
    address = @client.get_contract_address('0xe83de3583d345726e8d8377e76ec299989166af6cd4415513a34d00c4ffa159c')
    assert_equal '0xb2a1ac7f7253b0ebf6410920ed1342c974bca67a', address
  end

  def test_eth_newFilter
    filters = @client.eth_newFilter(1093429, 2103429, '0xbb9bc244d798123fde783fcc1c72d3bb8c189413', ['0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef'])

    assert_equal filters.size, 34
  end
end
