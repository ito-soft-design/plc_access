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
      class FxProtocol < Protocol
        attr_accessor :pc_no, :baudrate, :station_no, :wait_time

        STX = "\u0002"
        ETX = "\u0003"
        EOT = "\u0004"
        ENQ = "\u0005"
        ACK = "\u0006"
        LF  = "\u000a"
        CR  = "\u000d"
        NAK = "\u0015"

        DELIMITER = "\r\n"

        def initialize(options = {})
          super
          @port = options[:port] || `ls /dev/tty.usb*`.split("\n").map(&:chomp).first
          @pc_no = 0xff
          @baudrate = 19_200
          @station_no = 0
          @wait_time = 0
          @comm = nil
        end

        def open
          open!
        rescue StandardError
          nil
        end

        def open!
          return false unless @port

          begin
            # port, baudrate, bits, stop bits, parity(0:none, 1:even, 2:odd)
            @comm ||= SerialPort.new(@port, @baudrate, 7, 1, 2).tap do |s|
              s.read_timeout = (TIMEOUT * 1000.0).to_i
            end
            raise StandardError.new("invalid port #{@port}") unless @comm
          rescue StandardError => e
            p e
            nil
          end
        end

        def close
          @comm&.close
          @comm = nil
        end

        def get_bits_from_device(count, device)
          unless available_bits_range.include? count
            raise ArgumentError,
                  "A count #{count} must be between #{available_bits_range.first} and #{available_bits_range.last} for #{__method__}"
          end

          device = device_by_name device
          packet = body_for_get_bits_from_device(count, device) + DELIMITER
          @logger.debug("> #{dump_packet packet}")
          open
          @comm.write(packet)
          @comm.flush
          res = receive
          bits = []

          if res && (check_sum(res[0..-5]) == res[-4, 2])
            bits =
              res[5..-6].each_char.map do |c|
                c == '1'
              end
          end
          @logger.debug("> #{dump_packet ack_packet}")
          @comm.write(ack_packet)
          @logger.debug("get #{device.name} => #{bits}")

          bits
        end

        def set_bits_to_device(bits, device)
          unless available_bits_range.include? bits.size
            raise ArgumentError,
                  "A count #{count} must be between #{available_bits_range.first} and #{available_bits_range.last} for #{__method__}"
          end

          device = device_by_name device
          packet = body_for_set_bits_to_device(bits, device)
          @logger.debug("> #{dump_packet packet}")
          open
          @comm.write(packet)
          @comm.flush
          res = receive
          @logger.debug("set #{bits} to:#{device.name}")

          # error checking
          raise "ERROR: return #{res} for set_bits_to_device(#{bits}, #{device.name})" unless res == ack_packet
        end

        def get_words_from_device(count, device)
          unless available_words_range.include? count
            raise ArgumentError,
                  "A count #{count} must be between #{available_words_range.first} and #{available_words_range.last} for #{__method__}"
          end

          device = device_by_name device
          packet = body_for_get_words_from_device(count, device) + DELIMITER
          @logger.debug("> #{dump_packet packet}")
          open
          @comm.write(packet)
          @comm.flush
          res = receive
          words = []

          if res && (check_sum(res[0..-5]) == res[-4, 2])
            words =
              res[5..-6].scan(/.{4}/).map do |v|
                v.to_i(16)
              end
          end
          @logger.debug("> #{dump_packet ack_packet}")
          @comm.write(ack_packet)
          @logger.debug("get #{device.name} => #{words}")

          words
        end

        def set_words_to_device(words, device)
          unless available_bits_range.include? words.size
            raise ArgumentError,
                  "A count of words #{words.size} must be between #{available_words_range.first} and #{available_words_range.last} for #{__method__}"
          end

          device = device_by_name device
          packet = body_for_set_words_to_device(words, device)
          @logger.debug("> #{dump_packet packet}")
          open
          @comm.write(packet)
          @comm.flush
          res = receive
          @logger.debug("set #{words} to: #{device.name}")

          # error checking
          raise "ERROR: return #{res} for set_bits_to_device(#{words}, #{device.name})" unless res == ack_packet
        end

        def device_by_name(name)
          case name
          when String
            d = FxDevice.new name
            d.valid? ? d : nil
          else
            # it may be already QDevice
            name
          end
        end

        def receive
          res = ''
          begin
            Timeout.timeout(TIMEOUT) do
              res = @comm.gets
            end
            res
          rescue Timeout::Error
            puts "*** ERROR: TIME OUT : #{res} ***"
          end
          @logger.debug("< #{dump_packet res}")
          res
        end

        def available_bits_range(_device = nil)
          1..256
        end

        def available_words_range(_device = nil)
          1..64
        end

        def body_for_get_bit_from_deivce(device)
          body_for_get_bits_from_device 1, device
        end

        def body_for_get_bits_from_device(count, device)
          body = header_with_command 'BR'
          body += "#{device.name}#{count.to_s(16).rjust(2, '0')}"
          body += check_sum(body)
          body += DELIMITER
          body.upcase
        end

        def body_for_get_words_from_device(count, device)
          body = header_with_command 'WR'
          body += "#{device.name}#{count.to_s(16).rjust(2, '0')}"
          body += check_sum(body)
          body += DELIMITER
          body.upcase
        end

        def body_for_set_bits_to_device(bits, device)
          body = header_with_command 'BW'
          body += "#{device.name}#{bits.count.to_s(16).rjust(2, '0')}"
          body += bits.map { |b| b ? '1' : '0' }.join('')
          body += check_sum(body)
          body += DELIMITER
          body.upcase
        end
        alias body_for_set_bit_to_device body_for_set_bits_to_device

        def body_for_set_words_to_device(words, device)
          body = header_with_command 'WW'
          body += "#{device.name}#{words.count.to_s(16).rjust(2, '0')}"
          body += words.map { |w| w.to_s(16).rjust(4, '0') }.join('')
          body += check_sum(body)
          body += DELIMITER
          body.upcase
        end

        def dump_packet(packet)
          packet.inspect
        end

        private

        def check_sum(packet)
          packet[1..].upcase.unpack('C*').inject(0) { |s, c| s + c }.to_s(16).rjust(2, '0')[-2, 2].upcase
        end

        def header_with_command(command)
          "#{ENQ}#{station_no.to_s.rjust(2, '0')}#{pc_no.to_s(16).rjust(2, '0')}#{command}#{wait_time}".upcase
        end

        def ack_packet
          "#{ACK}#{station_no.to_s.rjust(2, '0')}#{pc_no.to_s(16).rjust(2, '0')}#{DELIMITER}".upcase
        end
      end
    end
  end
end
