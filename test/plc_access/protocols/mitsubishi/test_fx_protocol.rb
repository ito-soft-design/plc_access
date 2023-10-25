# frozen_string_literal: true

require 'test/unit'
require 'plc_access'

include PlcAccess

class TestFxProtocol < Test::Unit::TestCase
  include Protocol::Mitsubishi

  attr_reader :running

  def setup
    @protocol = FxProtocol.new log_level: :debug
    Timeout.timeout(0.5) do
      @running = !!@protocol.open
    end
  rescue Timeout::Error
  end

  def teardown
    @protocol.set_bits_to_device([false] * 8, FxDevice.new('M3000')) if @running
    @protocol.close
  end

  #   def test_open
  #     assert_not_nil @protocol.open
  #   end

  def test_set_and_read_bool_value
    omit_if(!running)
    d = FxDevice.new 'M3000'
    @protocol.set_bit_to_device(true, d)
    assert_equal true, @protocol.get_bit_from_device(d)
  end

  def test_set_and_read_word_value
    omit_if(!running)
    d = FxDevice.new 'D3000'
    @protocol.set_word_to_device(0x1234, d)
    assert_equal 0x1234, @protocol.get_word_from_device(d)
  end

  def test_set_and_read_bits
    omit_if(!running)
    d = FxDevice.new 'M3000'
    bits = '10010001'.each_char.map { |c| c == '1' }
    @protocol.set_bits_to_device(bits, d)
    @protocol.set_bits_to_device(bits, d)
    assert_equal bits, @protocol.get_bits_from_device(bits.size, d)
  end

  def test_set_and_read_words
    omit_if(!running)
    d = FxDevice.new 'D0'
    values = (256..265).to_a
    @protocol.set_words_to_device(values, d)
    assert_equal values, @protocol.get_words_from_device(values.size, d)
  end
end
