# eth_json_rpc
Ruby client for Ethereum using the JSON-RPC interface.

## Install

```shell
git clone https://github.com/u2/eth_json_rpc.git
cd eth_json_rpc
gem build eth_json_rpc.gemspec
gem install ./eth_json_rpc-0.0.2.gem
```

## Usage

```ruby
irb(main):001:0> require 'eth_json_rpc'
=> true
irb(main):002:0> EthJsonRpc::Client.new
=> #<EthJsonRpc::Client:0x007fe2e362bc18 @host="localhost", @port=8545, @tls=false>
irb(main):003:0> e=EthJsonRpc::Client.new
=> #<EthJsonRpc::Client:0x007fe2e356b9e0 @host="localhost", @port=8545, @tls=false>
irb(main):004:0> e.get_contract_address('0xe83de3583d345726e8d8377e76ec299989166af6cd4415513a34d00c4ffa159c')
=> "0xb2a1ac7f7253b0ebf6410920ed1342c974bca67a"
irb(main):005:0> e.web3_sha3('0x68656c6c6f20776f726c64')
=> "0x47173285a8d7341e5e972fc677286384f802f8ef42a5ec5f03bbfa254cb01fad"
irb(main):006:0> e.eth_coinbase
=> "0x319109cc083a381a64c40546c92358398b82d97f"
irb(main):007:0> e.eth_hashrate
=> 0
irb(main):008:0> e.eth_gasPrice
=> 20000000000
irb(main):009:0> e.eth_blockNumber
=> 2093741
irb(main):010:0> e.transfer('0x319109cc083a381a64c40546c92358398b82d97f', '0xE82D5B10ad98d34dF448b07a5a62C1aFfBEf758F', 100000000000000000000)
StandardError: {"code"=>-32000, "message"=>"account is locked"}
```
