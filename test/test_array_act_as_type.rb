require 'test/unit'
require 'plc_access'

using PlcAccess::ArrayActAsType

class TestArrayActAsType < Test::Unit::TestCase

  attr_reader :running

  def setup
    @a = [1, 0, -1, 0, 1, 1, -1, -1]
  end

  def test_to_usort
    assert_equal [1, 0, 65535, 0, 1, 1, 65535, 65535], @a.to_ushort
  end

  def test_to_sort
    assert_equal [1, 0, -1, 0, 1, 1, -1, -1], @a.to_short
  end

  def test_to_uint
    assert_equal [1, 0xffff, 0x10001, 0xffffffff], @a.to_uint
  end

  def test_to_int
    assert_equal [1, 65535, 0x10001, -1], @a.to_int
  end

  def test_to_float
    assert_equal [1.401298464324817e-45, 9.183409485952689e-41, 9.183689745645554e-41], @a[0..-3].to_float
  end

  def test_as_ushort
    assert_equal @a.as_ushort, [1, 0, 65535, 0, 1, 1, 65535, 65535].as_ushort
  end
  
  def test_as_short
    assert_equal @a.as_ushort, [1, 0, -1, 0, 1, 1, -1, -1].as_ushort
  end
  
  def test_as_uint
    assert_equal @a.as_ushort, [1, 0xffff, 0x10001, 0xffffffff].as_uint
  end

  def test_as_int
    assert_equal @a.as_ushort, [1, 65535, 0x10001, -1].as_int
  end

  def test_as_int
    assert_equal @a[0..-3].as_ushort, [1.401298464324817e-45, 9.183409485952689e-41, 9.183689745645554e-41].as_float
  end

end
