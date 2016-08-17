module EthJsonRpc
  module Constants
    BLOCK_TAG_EARLIEST = "earliest".freeze
    BLOCK_TAG_LATEST   = "latest".freeze
    BLOCK_TAG_PENDING  = "pending".freeze
    BLOCK_TAGS = [BLOCK_TAG_EARLIEST, BLOCK_TAG_LATEST, BLOCK_TAG_PENDING].freeze

    GETH_DEFAULT_RPC_PORT = 8545
    ETH_DEFAULT_RPC_PORT = 8545
    PARITY_DEFAULT_RPC_PORT = 8080
    PYETHAPP_DEFAULT_RPC_PORT = 4000

    DEFAULT_GAS_PER_TX = 90000
    DEFAULT_GAS_PRICE = 50 * 10**9  # 50 gwei

    # https://github.com/janx/ruby-ethereum/blob/master/lib/ethereum/constant.rb
    BYTE_EMPTY = "".freeze
    BYTE_ZERO = "\x00".freeze
    BYTE_ONE  = "\x01".freeze

    TT32  = 2**32
    TT256 = 2**256
    TT64M1 = 2**64 - 1

    UINT_MAX = 2**256 - 1
    UINT_MIN = 0
    INT_MAX = 2**255 - 1
    INT_MIN = -2**255

    HASH_ZERO = ("\x00"*32).freeze

    PUBKEY_ZERO = ("\x00"*32).freeze
    PRIVKEY_ZERO = ("\x00"*32).freeze
    PRIVKEY_ZERO_HEX = ('0'*64).freeze
  end
end
