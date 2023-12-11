require 'test/unit'
require 'plc_access'

using PlcAccess::ArrayActAsType
using PlcAccess::StringActAsType

class TestStringActAsType < Test::Unit::TestCase

  attr_reader :running

  def test_to_usort
    assert_equal [0x3130, 0x3332, 0x3534, 0x3736, 0x3938], "0123456789".to_ushort
  end

  def test_to_usort_with_length_8
    assert_equal [0x3130, 0x3332, 0x3534, 0x3736], "01234567".to_ushort(8)
  end

  def test_to_usort_with_length_16
    assert_equal [0x3130, 0x3332, 0x3534, 0x3736, 0x3938, 0x0000, 0x0000, 0x0000], "0123456789".to_ushort(16)
  end

  def test_to_usort_with_sjis
    assert_equal [0xa082, 0xa282, 0xa482, 0xa682, 0xa882], "あいうえお".to_ushort(nil, Encoding::Shift_JIS)
  end

  def test_as_string
    assert_equal "0123456789",[0x3130, 0x3332, 0x3534, 0x3736, 0x3938].as_string
  end

  def test_as_string_with_length_8
    assert_equal "01234567",[0x3130, 0x3332, 0x3534, 0x3736].as_string(8)
  end

  def test_as_string_with_length_4
    assert_equal "0123",[0x3130, 0x3332, 0x3534, 0x3736].as_string(4)
  end

  def test_as_string_with_length_12_and_triming
    assert_equal "01234567",[0x3130, 0x3332, 0x3534, 0x3736, 0x0000, 0x0000].as_string(12)
  end

  def test_as_string_with_sjis
    assert_equal "あいうえお", [0xa082, 0xa282, 0xa482, 0xa682, 0xa882].as_string(nil, Encoding::Shift_JIS)
  end


end
