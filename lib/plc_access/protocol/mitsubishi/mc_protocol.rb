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
  module Protocol
    module Mitsubishi
      class McProtocol < Protocol
        def initialize(options = {})
          super
          @socket = nil
          @host = options[:host] || '192.168.0.10'
          @port = options[:port] || 5010
        end

        def open
          open!
        rescue StandardError
          nil
        end

        def open!
          @socket ||= TCPSocket.open(@host, @port)
        end

        def close
          @socket&.close
          @socket = nil
        end

        def get_bits_from_device(count, device)
          unless available_bits_range.include? count
            raise ArgumentError,
                  "A count #{count} must be between #{available_bits_range.first} and #{available_bits_range.last} for #{__method__}"
          end

          device = device_by_name device
          packet = make_packet(body_for_get_bits_from_device(count, device))
          @logger.debug("> #{dump_packet packet}")
          open
          @socket.write(packet.pack('C*'))
          @socket.flush
          res = receive

          # error checking
          end_code = res[9, 2].pack('C*').unpack1('v')
          unless end_code.zero?
            error = res[11, 2].pack('C*').unpack1('v')
            raise "return end code 0x#{end_code.to_s(16)} error code 0x#{error.to_s(16)} for get_bits_from_device(#{count}, #{device.name})"
          end

          # get results
          bits = []
          count.times do |i|
            v = res[11 + i / 2]
            bits << if i.even?
                      ((v >> 4) != 0)
                    else
                      ((v & 0xf) != 0)
                    end
          end
          @logger.debug("get #{device.name} => #{bits}")
          bits
        end

        def set_bits_to_device(bits, device)
          unless available_bits_range.include? bits.size
            raise ArgumentError,
                  "A count #{count} must be between #{available_bits_range.first} and #{available_bits_range.last} for #{__method__}"
          end

          device = device_by_name device
          packet = make_packet(body_for_set_bits_to_device(bits, device))
          @logger.debug("> #{dump_packet packet}")
          open
          @socket.write(packet.pack('C*'))
          @socket.flush
          res = receive
          @logger.debug("set #{bits} to:#{device.name}")

          # error checking
          end_code = res[9, 2].pack('C*').unpack1('v')
          unless end_code.zero?
            error = res[11, 2].pack('C*').unpack1('v')
            raise "return end code 0x#{end_code.to_s(16)} error code 0x#{error.to_s(16)} for set_bits_to_device(#{bits}, #{device.name})"
          end
        end

        def get_words_from_device(count, device)
          unless available_bits_range.include? count
            raise ArgumentError,
                  "A count #{count} must be between #{available_words_range.first} and #{available_words_range.last} for #{__method__}"
          end

          device = device_by_name device
          packet = make_packet(body_for_get_words_from_device(count, device))
          @logger.debug("> #{dump_packet packet}")
          open
          @socket.write(packet.pack('C*'))
          @socket.flush
          res = receive

          # error checking
          end_code = res[9, 2].pack('C*').unpack1('v')
          unless end_code.zero?
            error = res[11, 2].pack('C*').unpack1('v')
            raise "return end code 0x#{end_code.to_s(16)} error code 0x#{error.to_s(16)} for get_words_from_device(#{count}, #{device.name})"
          end

          # get result
          words = []
          res[11, 2 * count].each_slice(2) do |pair|
            words << pair.pack('C*').unpack1('v')
          end
          @logger.debug("get from: #{device.name} => #{words}")
          words
        end

        def set_words_to_device(words, device)
          unless available_bits_range.include? words.size
            raise ArgumentError,
                  "A count of words #{words.size} must be between #{available_words_range.first} and #{available_words_range.last} for #{__method__}"
          end

          device = device_by_name device
          packet = make_packet(body_for_set_words_to_device(words, device))
          @logger.debug("> #{dump_packet packet}")
          open
          @socket.write(packet.pack('C*'))
          @socket.flush
          res = receive
          @logger.debug("set #{words} to: #{device.name}")

          # error checking
          end_code = res[9, 2].pack('C*').unpack1('v')
          unless end_code.zero?
            error = res[11, 2].pack('C*').unpack1('v')
            raise "return end code 0x#{end_code.to_s(16)} error code 0x#{error.to_s(16)} for set_words_to_device(#{words}, #{device.name})"
          end
        end

        def device_by_name(name)
          case name
          when String
            d = QDevice.new name
            d.valid? ? d : nil
          else
            # it may be already QDevice
            name
          end
        end

        def receive
          res = []
          len = 0
          begin
            Timeout.timeout(TIMEOUT) do
              loop do
                c = @socket.read(1)
                next if c.nil? || c == ''

                res << c.bytes.first
                len = res[7, 2].pack('C*').unpack1('v*') if res.length >= 9
                break if len + 9 == res.length
              end
            end
          rescue Timeout::Error
            puts '*** ERROR: TIME OUT ***'
          end
          @logger.debug("< #{dump_packet res}")
          res
        end

        def available_bits_range(_device = nil)
          1..(960 * 16)
        end

        def available_words_range(_device = nil)
          1..960
        end

        private

        def make_packet(body)
          header = [0x50, 0x00, 0x00, 0xff, 0xff, 0x03, 0x00, 0x00, 0x00, 0x10, 0x00]
          header[7..8] = data_for_short(body.length + 2)
          header + body
        end

        def body_for_get_bit_from_deivce(device)
          body_for_get_bits_from_device 1, device
        end

        def body_for_get_bits_from_device(count, device)
          body_for_get_words_from_device count, device, false
        end

        def body_for_get_words_from_device(count, device, word = true)
          body = [0x01, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x90, 0x01, 0x00]
          body[2] = 1 unless word
          body[4..7] = data_for_device(device)
          body[8..9] = data_for_short count
          body
        end

        def body_for_set_bits_to_device(bits, device)
          body = [0x01, 0x14, 0x01, 0x00, 0x00, 0x00, 0x00, 0x90, 0x01, 0x00]
          d = device
          bits = [bits] unless bits.is_a? Array
          bits.each_slice(2) do |pair|
            body << (pair.first ? 0x10 : 0x00)
            body[-1] |= (pair.last ? 0x1 : 0x00) if pair.size == 2
            d = d.next_device
          end
          body[4..7] = data_for_device(device)
          body[8..9] = data_for_short bits.size
          body
        end
        alias body_for_set_bit_to_device body_for_set_bits_to_device

        def body_for_set_words_to_device(words, device)
          body = [0x01, 0x14, 0x00, 0x00, 0x00, 0x00, 0x00, 0x90, 0x01, 0x00]
          d = device
          words = [words] unless words.is_a? Array
          words.each do |v|
            body += data_for_short v
            d = d.next_device
          end
          body[4..7] = data_for_device(device)
          body[8..9] = data_for_short words.size
          body
        end

        def data_for_device(device)
          a = data_for_int device.number
          a[3] = device.suffix_code
          a
        end

        def data_for_short(value)
          [value].pack('v').unpack('C*')
        end

        def data_for_int(value)
          [value].pack('V').unpack('C*')
        end

        def dump_packet(packet)
          a = []
          len = packet.length
          bytes = packet.dup
          len.times do |i|
            a << "0#{bytes[i].to_s(16)}"[-2, 2]
          end
          "[#{a.join(', ')}]"
        end
      end
    end
  end
end
