# frozen_string_literal: true

require 'test/unit'
require 'plc_access'

include PlcAccess

class TestMcProtocol < Test::Unit::TestCase
  include Protocol::Mitsubishi

  attr_reader :running

  def setup
    @protocol = McProtocol.new host: '10.0.1.202', port: 5010, log_level: :debug
    Timeout.timeout(0.5) do
      @running = !@protocol.open.nil?
    end
  rescue Timeout::Error
  end

  def teardown
    @protocol.close
  end

  #   def test_open
  #     assert_not_nil @protocol.open
  #   end

  def test_set_and_read_bool_value
    omit_if(!running)
    d = QDevice.new 'M0'
    @protocol.set_bit_to_device(true, d)
    assert_equal true, @protocol.get_bit_from_device(d)
  end

  def test_set_and_read_word_value
    omit_if(!running)
    d = QDevice.new 'D0'
    @protocol.set_word_to_device(0x1234, d)
    assert_equal 0x1234, @protocol.get_word_from_device(d)
  end

  def test_set_and_read_bits
    omit_if(!running)
    d = QDevice.new 'M0'
    bits = '10010001'.each_char.map { |c| c == '1' }
    @protocol.set_bits_to_device(bits, d)
    assert_equal bits, @protocol.get_bits_from_device(bits.size, d)
  end

  def test_set_and_read_words
    omit_if(!running)
    d = QDevice.new 'D0'
    values = (256..265).to_a
    @protocol.set_words_to_device(values, d)
    assert_equal values, @protocol.get_words_from_device(values.size, d)
  end

  # array attr_accessor
  def test_set_and_get_bit_as_array
    omit_if(!running)
    d = QDevice.new 'M0'
    bits = '10010001'.each_char.map { |c| c == '1' }
    @protocol[d, bits.size] = bits
    assert_equal bits, @protocol[d, bits.size]
  end

  def test_set_and_get_bit_as_array_with_range
    omit_if(!running)
    bits = '10010001'.each_char.map { |c| c == '1' }
    @protocol['M0'..'M7'] = bits
    assert_equal bits, @protocol['M0'..'M7']
  end

  def test_set_and_get_bit_as_array_with_one
    omit_if(!running)
    bits = '10010001'.each_char.map { |c| c == '1' }
    @protocol['M0'] = true
    assert_equal true, @protocol['M0']
  end

  def test_set_and_get_words_as_array
    omit_if(!running)
    d = QDevice.new 'D0'
    values = (256..265).to_a
    @protocol[d, values.size] = values
    assert_equal values, @protocol[d, values.size]
  end

  def test_set_and_get_words_as_array_with_range
    omit_if(!running)
    d = QDevice.new 'D0'
    values = (256..265).to_a
    @protocol['D0'..'D9'] = values
    assert_equal values, @protocol['D0'..'D9']
  end

  def test_set_and_get_words_as_array_with_one
    omit_if(!running)
    d = QDevice.new 'D0'
    @protocol['D0'] = 123
    assert_equal 123, @protocol['D0']
  end
end
