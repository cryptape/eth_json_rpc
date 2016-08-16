module EthJsonRpc
  module Exception
    class EthJsonRpcError < StandardError; end

    class ConnectionError < EthJsonRpcError; end

    class BadStatusCodeError < EthJsonRpcError; end

    class BadJsonError < EthJsonRpcError; end

    class BadResponseError < EthJsonRpcError; end
  end
end
