require 'test_helper'

class UtilsTest < Minitest::Test
  include EthJsonRpc::Utils
  include EthJsonRpc::Constants

  def test_hex_to_dec
    assert_equal hex_to_dec("0xb"), 11
  end

  def test_validate_block_when_integer
    assert_equal validate_block(15), "0xf"
  end

  def test_validate_block_when_block_tags
    assert_equal validate_block(BLOCK_TAG_EARLIEST), BLOCK_TAG_EARLIEST
  end

  def test_validate_raise_error
    assert_raises ArgumentError do
      validate_block('abc')
    end
  end

  def test_wei_to_ether
    assert_equal wei_to_ether(10**18), 1
  end

  def test_ether_to_wei
    assert_equal ether_to_wei(1), 10**18
  end

  def test_encode_to_hex
    assert_equal encode_to_hex('abd8'), "61626438"
  end
end