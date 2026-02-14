require 'test/unit'
require 'plc_access'

class TestProtocol < Test::Unit::TestCase

  class StubDevice
    attr_accessor :suffix, :number

    def initialize(name)
      /([A-Z]+)(\d+)/i =~ name
      @suffix = ::Regexp.last_match(1).upcase
      @number = ::Regexp.last_match(2).to_i
    end

    def bit_device?
      false
    end

    def +(other)
      d = self.class.new("#{@suffix}#{@number + other}")
      d
    end
  end

  class StubProtocol < PlcAccess::Protocol::Protocol
    attr_reader :last_written_words, :last_written_device

    def initialize
      super
      @last_written_words = nil
      @last_written_device = nil
    end

    def device_by_name(name)
      case name
      when String
        StubDevice.new(name)
      else
        name
      end
    end

    def set_words_to_device(words, device)
      @last_written_words = words
      @last_written_device = device
    end

    def available_words_range(_device = nil)
      1..10000
    end
  end

  def setup
    @plc = StubProtocol.new
  end

  # plc["DM0"] = array writes array.size words
  def test_set_array_without_count
    @plc["DM0"] = [1, 2, 3]
    assert_equal [1, 2, 3], @plc.last_written_words
  end

  # plc["DM0"] = scalar writes 1 word (existing behavior)
  def test_set_scalar_without_count
    @plc["DM0"] = 123
    assert_equal [123], @plc.last_written_words
  end

  # plc["DM0", 5] = [1,2,3] pads with zeros
  def test_set_array_shorter_than_count
    @plc["DM0", 5] = [1, 2, 3]
    assert_equal [1, 2, 3, 0, 0], @plc.last_written_words
  end

  # plc["DM0", 3] = [1,2,3,4,5] truncates
  def test_set_array_longer_than_count
    @plc["DM0", 3] = [1, 2, 3, 4, 5]
    assert_equal [1, 2, 3], @plc.last_written_words
  end

  # plc["DM0", 3] = [1,2,3] exact match still works
  def test_set_array_exact_count
    @plc["DM0", 3] = [1, 2, 3]
    assert_equal [1, 2, 3], @plc.last_written_words
  end

end
