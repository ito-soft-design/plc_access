# frozen_string_literal: true

# The MIT License (MIT)
#
# Copyright (c) 2016 ITO SOFT DESIGN Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module PlcAccess
  class PlcDevice
    attr_reader :suffix, :number
    attr_accessor :value

    NUMBER_TYPE_DEC     = 0
    NUMBER_TYPE_DEC_HEX = 1
    NUMBER_TYPE_HEX     = 2

    ESC_SUFFIXES = %w[X Y M - C T L SC CC TC D - CS TS H SD].freeze

    class << self
      def status_to_plc_device
        @status_to_plc_device ||= new 'SD0'
      end

      def status_from_plc_device
        @status_from_plc_device ||= new 'SD1'
      end

      def program_area_device
        @program_area_device ||= new 'PRG0'
      end
    end

    def initialize(a, b = nil)
      @suffix = nil
      @value = 0
      case a
      when Integer
        @suffix = ESC_SUFFIXES[a]
        @number = b
      when String, Symbol
        a = a.to_s # convert to string if it's a symbol
        if b
          @suffix = a.upcase
          @number = b
        else
          /([A-Z]+)?([0-9A-F]+)/i =~ a
          @suffix = (::Regexp.last_match(1) || '').upcase
          case number_type
          when NUMBER_TYPE_DEC_HEX
            n = ::Regexp.last_match(2).to_i
            @number = (n / 100) * 16 + (n % 100)
          when NUMBER_TYPE_HEX
            @number = ::Regexp.last_match(2).to_i(16)
          else
            @number = ::Regexp.last_match(2).to_i
          end
        end
      end
    end

    def name
      case number_type
      when NUMBER_TYPE_DEC
        "#{@suffix}#{@number}"
      when NUMBER_TYPE_DEC_HEX
        a = [@number / 16, @number % 16]
        ns = begin
          s = a.last.to_s.rjust(2, '0')
          s = a.first.to_s + s unless a.first.zero?
          s
        end
        "#{@suffix}#{ns}"
      when NUMBER_TYPE_HEX
        ns = @number.to_s(16).upcase
        ns = "0#{ns}" unless /^[0-9]/ =~ ns
        "#{@suffix}#{ns}"
      end
    end

    # NOTE: override at subclass
    #       It should get from plc
    def device_by_suffix_number(suffix, number)
      self.class.new suffix, number
    end

    def next_device
      device_by_suffix_number @suffix, @number + 1
    end

    def bit_device?
      suffixes_for_bit.include? @suffix
    end

    def +(other)
      device_by_suffix_number suffix, number + other
    end

    def -(other)
      device_by_suffix_number suffix, [number - other, 0].max
    end

    def input?
      suffixes_for_input.include? @suffix
    end

    def value
      case @value
      when true
        1
      when false, nil
        0
      else
        @value
      end
    end

    def bool
      case @value
      when Integer
        @value != 0
      else
        !!@value
      end
    end

    def bool=(v)
      @value = v
    end
    alias word value
    alias word= value=

    def string_endian
      :big
    end

    def text(len = 8)
      n = (len + 1) / 2
      d = self
      a = []
      n.times do
        a << d.value
        d = d.next_device
      end
      format = string_endian == :big ? 'n*' : 'v*'
      s = a.pack(format).split("\x00").first
      s ? s[0, len] : ''
    end

    def set_text(value, len = 8)
      value = value[0, len]
      value << "\00" unless value.length.even?
      format = string_endian == :big ? 'n*' : 'v*'
      a = value.unpack(format)
      d = self
      a.each do |v|
        d.value = v
        d = d.next_device
      end
    end

    def text=(value)
      set_text value
    end

    def device_code
      ESC_SUFFIXES.index @suffix
    end

    def reset
      @value = 0
    end

    private

    SUFFIXES_FOR_DEC      = %w[PRG M C T L SC CC TC D CS TS H SD].freeze
    SUFFIXES_FOR_DEC_HEX  = %w[].freeze
    SUFFIXES_FOR_HEX      = %w[X Y].freeze
    SUFFIXES_FOR_BIT      = %w[X Y M C T L SC].freeze
    SUFFIXES_FOR_INPUT    = %w[X].freeze

    def suffixes_for_dec
      SUFFIXES_FOR_DEC
    end

    def suffixes_for_dec_hex
      SUFFIXES_FOR_DEC_HEX
    end

    def suffixes_for_hex
      SUFFIXES_FOR_HEX
    end

    def suffixes_for_bit
      SUFFIXES_FOR_BIT
    end

    def suffixes_for_input
      SUFFIXES_FOR_INPUT
    end

    def suffixes
      suffixes_for_dec + suffixes_for_dec_hex + suffixeds_for_hex
    end

    def number_type
      return NUMBER_TYPE_DEC if suffixes_for_dec.include? @suffix
      return NUMBER_TYPE_DEC_HEX if suffixes_for_dec_hex.include? @suffix
      return NUMBER_TYPE_HEX if suffixes_for_hex.include? @suffix

      nil
    end
  end
end
