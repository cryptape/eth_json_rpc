module EthJsonRpc
  module Constant
    BLOCK_TAG_EARLIEST = "earliest".freeze
    BLOCK_TAG_LATEST   = "latest".freeze
    BLOCK_TAG_PENDING  = "pending".freeze
    BLOCK_TAGS = [BLOCK_TAG_EARLIEST, BLOCK_TAG_LATEST, BLOCK_TAG_PENDING].freeze
  end
end
