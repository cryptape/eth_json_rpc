$:.push File.expand_path("../lib", __FILE__)

require "eth_json_rpc/version"

Gem::Specification.new do |s|
  s.name        = 'eth_json_rpc'
  s.version     = EthJsonRpc::VERSION
  s.date        = '2016-08-16'
  s.summary     = "Ruby Ethereum JSON RPC"
  s.description = "Ruby client for Ethereum using the JSON-RPC interface"
  s.authors     = ["ZhangYaNing"]
  s.email       = 'zhangyaning1985@gmail.com'
  s.files       = ["lib/eth_json_rpc.rb"]
  s.homepage    = 'https://github.com/u2/eth_json_rpc'
  s.license     = 'MIT'

  s.files = Dir["{lib}/**/*"] + ["LICENSE", "README.md"]

  s.add_development_dependency('minitest', '5.8.3')
end
