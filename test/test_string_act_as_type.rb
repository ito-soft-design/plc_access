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

  # Big endian tests

  def test_as_ushort_big_endian
    assert_equal [0x3031, 0x3233, 0x3435, 0x3637, 0x3839], "0123456789".as_ushort(endian: :big)
  end

  def test_as_ushort_big_endian_with_length_8
    assert_equal [0x3031, 0x3233, 0x3435, 0x3637], "01234567".as_ushort(8, endian: :big)
  end

  def test_as_ushort_big_endian_with_length_16
    assert_equal [0x3031, 0x3233, 0x3435, 0x3637, 0x3839, 0x0000, 0x0000, 0x0000], "0123456789".as_ushort(16, endian: :big)
  end

  def test_as_ushort_big_endian_with_sjis
    assert_equal [0x82a0, 0x82a2, 0x82a4, 0x82a6, 0x82a8], "あいうえお".as_ushort(nil, Encoding::Shift_JIS, endian: :big)
  end

  def test_to_string_big_endian
    assert_equal "0123456789", [0x3031, 0x3233, 0x3435, 0x3637, 0x3839].to_string(endian: :big)
  end

  def test_to_string_big_endian_with_length_8
    assert_equal "01234567", [0x3031, 0x3233, 0x3435, 0x3637].to_string(8, endian: :big)
  end

  def test_to_string_big_endian_with_length_4
    assert_equal "0123", [0x3031, 0x3233, 0x3435, 0x3637].to_string(4, endian: :big)
  end

  def test_to_string_big_endian_with_sjis
    assert_equal "あいうえお", [0x82a0, 0x82a2, 0x82a4, 0x82a6, 0x82a8].to_string(nil, Encoding::Shift_JIS, endian: :big)
  end

  # plc argument tests

  def test_as_ushort_with_plc_big_endian
    plc = Struct.new(:string_endian).new(:big)
    assert_equal [0x3031, 0x3233, 0x3435, 0x3637, 0x3839], "0123456789".as_ushort(plc)
  end

  def test_as_ushort_with_plc_little_endian
    plc = Struct.new(:string_endian).new(:little)
    assert_equal [0x3130, 0x3332, 0x3534, 0x3736, 0x3938], "0123456789".as_ushort(plc)
  end

  def test_as_ushort_with_length_and_plc
    plc = Struct.new(:string_endian).new(:big)
    assert_equal [0x3031, 0x3233, 0x3435, 0x3637], "01234567".as_ushort(8, plc)
  end

  def test_to_string_with_plc_big_endian
    plc = Struct.new(:string_endian).new(:big)
    assert_equal "0123456789", [0x3031, 0x3233, 0x3435, 0x3637, 0x3839].to_string(plc)
  end

  def test_to_string_with_plc_little_endian
    plc = Struct.new(:string_endian).new(:little)
    assert_equal "0123456789", [0x3130, 0x3332, 0x3534, 0x3736, 0x3938].to_string(plc)
  end

  def test_to_string_with_length_and_plc
    plc = Struct.new(:string_endian).new(:big)
    assert_equal "0123", [0x3031, 0x3233, 0x3435, 0x3637].to_string(4, plc)
  end


end
