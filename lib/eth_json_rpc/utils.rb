require 'digest/sha3'
require "eth_json_rpc/constants"
require "eth_json_rpc/exception"

module EthJsonRpc
  module Utils
    include Constants
    include Exception

    def hex_to_dec(x)
      x.to_i(16)
    end

    def validate_block(block)
      case block
      when Integer
        block = "0x" + block.to_s(16)
      else String
        raise ArgumentError, 'invalid block tag' if !BLOCK_TAGS.include?(block)
      end
      block
    end

    def wei_to_ether(wei)
      1.0 * wei / 10**18
    end

    def ether_to_wei(ether)
      ether * 10**18
    end

    ##
    # Not the keccak in sha3, although it's underlying lib named SHA3
    #
    def keccak256(x)
      Digest::SHA3.new(256).digest(x)
    end

    def keccak512(x)
      Digest::SHA3.new(512).digest(x)
    end

    def encode_to_hex(str)
      str.unpack('U*').map{|i| i.to_s(16) }.join
    end

    def int_to_hex(i)
      '0x' + i.to_s(16)
    end
  end
end
