require_relative "constant"
require_relative "exception"

module EthJsonRpc
  module Util
    include Constant
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
  end
end
