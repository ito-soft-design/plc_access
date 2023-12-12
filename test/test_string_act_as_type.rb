require 'test/unit'
require 'plc_access'

using PlcAccess::ActAsType

class TestStringActAsType < Test::Unit::TestCase

  attr_reader :running

  def test_as_usort
    assert_equal [0x3130, 0x3332, 0x3534, 0x3736, 0x3938], "0123456789".as_ushort
  end

  def test_as_usort_with_length_8
    assert_equal [0x3130, 0x3332, 0x3534, 0x3736], "01234567".as_ushort(8)
  end

  def test_as_usort_with_length_16
    assert_equal [0x3130, 0x3332, 0x3534, 0x3736, 0x3938, 0x0000, 0x0000, 0x0000], "0123456789".as_ushort(16)
  end

  def test_as_usort_with_sjis
    assert_equal [0xa082, 0xa282, 0xa482, 0xa682, 0xa882], "あいうえお".as_ushort(nil, Encoding::Shift_JIS)
  end

  def test_to_string
    assert_equal "0123456789",[0x3130, 0x3332, 0x3534, 0x3736, 0x3938].to_string
  end

  def test_to_string_with_length_8
    assert_equal "01234567",[0x3130, 0x3332, 0x3534, 0x3736].to_string(8)
  end

  def test_to_string_with_length_4
    assert_equal "0123",[0x3130, 0x3332, 0x3534, 0x3736].to_string(4)
  end

  def test_to_string_with_length_12_and_triming
    assert_equal "01234567",[0x3130, 0x3332, 0x3534, 0x3736, 0x0000, 0x0000].to_string(12)
  end

  def test_to_string_with_sjis
    assert_equal "あいうえお", [0xa082, 0xa282, 0xa482, 0xa682, 0xa882].to_string(nil, Encoding::Shift_JIS)
  end


end
