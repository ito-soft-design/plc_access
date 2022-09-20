# The MIT License (MIT)
#
# Copyright (c) 2019 ITO SOFT DESIGN Inc.
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
    module Omron
      class FinsTcpProtocol < Protocol
        attr_accessor :gateway_count, :destination_network, :destination_node, :destination_unit, :source_network,
                      :source_node, :source_unit, :ethernet_module, :tcp_error_code

        IOFINS_DESTINATION_NODE_FROM_IP = 0
        IOFINS_SOURCE_AUTO_NODE         = 0

        # Available ethernet module.
        ETHERNET_ETN21  = 0
        ETHERNET_CP1E   = 1
        ETHERNET_CP1L   = 2
        ETHERNET_CP1H   = 3

        TIMEOUT = 5.0

        def initialize(options = {})
          super
          @socket = nil
          @host = options[:host] || '192.168.250.1'
          @port = options[:port] || 9600
          @gateway_count = 3
          @destination_network = 0
          @destination_node = 0
          @destination_unit = 0
          @source_network = 0
          @source_node = IOFINS_SOURCE_AUTO_NODE
          @source_unit = 0
          @ethernet_module = ETHERNET_ETN21

          @tcp_error_code = 0
        end

        def open
          open!
        rescue StandardError => e
          p e
          nil
        end

        def open!
          if @socket.nil?
            @socket = TCPSocket.open(@host, @port)
            if @socket
              self.source_node = IOFINS_SOURCE_AUTO_NODE
              query_node
            end
          end
          @socket
        end

        def close
          @socket.close if @socket
          @socket = nil
        end

        def tcp_error?
          tcp_error_code != 0
        end

        def create_query_node
          header = ['FINS'.bytes.to_a, 0, 0, 0, 0xc, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0].flatten
          header[19] = source_node == IOFINS_SOURCE_AUTO_NODE ? 0 : source_node
          header
        end

        def create_fins_frame(packet)
          packet = packet.flatten
          header = ['FINS'.bytes.to_a, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0].flatten
          header[4, 4] = int_to_a(packet.length + 8, 4)
          header + packet
        end

        def get_bits_from_device(count, device)
          open
          unless available_bits_range.include? count
            raise ArgumentError,
                  "A count #{count} must be between #{available_bits_range.first} and #{available_bits_range.last} for #{__method__}"
          end

          device = device_by_name device
          raise ArgumentError, "#{device.name} is not bit device!" unless device.bit_device?

          command = [1, 1]
          command << device_to_a(device)
          command << int_to_a(count, 2)

          send_packet create_fins_frame(fins_header + command)
          res = receive

          count.times.each_with_object([]) do |i, a|
            a << (!(res[16 + 10 + 4 + i] == 0))
          end
        end

        def get_words_from_device(count, device)
          open
          unless available_words_range.include? count
            raise ArgumentError,
                  "A count #{count} must be between #{available_words_range.first} and #{available_words_range.last} for #{__method__}"
          end

          device = device_by_name device
          device = device.channel_device

          command = [1, 1]
          command << device_to_a(device)
          command << int_to_a(count, 2)

          send_packet create_fins_frame(fins_header + command)
          res = receive
          count.times.each_with_object([]) do |i, a|
            a << to_int(res[16 + 10 + 4 + i * 2, 2])
          end
        end

        def set_bits_to_device(bits, device)
          open
          count = bits.size
          unless available_bits_range.include? count
            raise ArgumentError,
                  "A count #{count} must be between #{available_bits_range.first} and #{available_bits_range.last} for #{__method__}"
          end

          device = device_by_name device
          raise ArgumentError, "#{device.name} is not bit device!" unless device.bit_device?

          command = [1, 2]
          command << device_to_a(device)
          command << int_to_a(count, 2)
          bits.each do |b|
            command << (b ? 1 : 0)
          end

          send_packet create_fins_frame(fins_header + command)
          receive
        end

        def set_words_to_device(words, device)
          open
          count = words.size
          unless available_words_range.include? count
            raise ArgumentError,
                  "A count #{count} must be between #{available_words_range.first} and #{available_words_range.last} for #{__method__}"
          end

          device = device_by_name device
          device = device.channel_device

          command = [1, 2]
          command << device_to_a(device)
          command << int_to_a(count, 2)
          words.each do |w|
            command << int_to_a(w, 2)
          end

          send_packet create_fins_frame(fins_header + command)
          receive
        end

        def query_node
          send_packet create_query_node
          res = receive
          self.source_node = res[19]
        end

        def send_packet(packet)
          @socket.write(packet.flatten.pack('c*'))
          @socket.flush
          @logger.debug("> #{dump_packet packet}")
        end

        def receive
          res = []
          len = 0
          begin
            Timeout.timeout(TIMEOUT) do
              loop do
                c = @socket.getc
                next if c.nil? || c == ''

                res << c.bytes.first
                next if res.length < 8

                len = to_int(res[4, 4])
                next if res.length < 8 + len

                tcp_command = to_int(res[8, 4])
                case tcp_command
                when 3 # ERROR
                  raise "Invalidate tcp header: #{res}"
                end
                break
              end
            end
            raise "Response error code: #{res[15]}" unless res[15] == 0

            res
          end
          @logger.debug("< #{dump_packet res}")
          res
        end

        # max length:
        #  CS1W-ETN21, CJ1W-ETN21   : 2012
        #  CP1W-CIF41 option board  : 540 (1004 if cpu is CP1L/H)

        def available_bits_range(_device = nil)
          case ethernet_module
          when ETHERNET_ETN21
            1..(2012 - 8)
          when ETHERNET_CP1E
            1..(540 - 8)
          when ETHERNET_CP1L, ETHERNET_CP1H
            1..(1004 - 8)
          else
            0..0
          end
        end

        def available_words_range(_device = nil)
          case ethernet_module
          when ETHERNET_ETN21
            1..((2012 - 8) / 2)
          when ETHERNET_CP1E
            1..((540 - 8) / 2)
          when ETHERNET_CP1L, ETHERNET_CP1H
            1..((1004 - 8) / 2)
          else
            0..0
          end
        end

        def device_by_name(name)
          case name
          when String
            d = OmronDevice.new name
            d.valid? ? d : nil
          else
            # it may be already OmronDevice
            name
          end
        end

        private

        def fins_header
          buf = [
            0x80, # ICF
            0x00, # RSV
            0x02, # GCT
            0x00, # DNA
            0x01, # DA1
            0x00, # DA2
            0x00, # SNA
            0x01, # SA1
            0x00, # SA2
            0x00 # SID
          ]
          buf[2] = gateway_count - 1
          buf[3] = destination_network
          buf[4] = if destination_node == IOFINS_DESTINATION_NODE_FROM_IP
                     destination_ipv4.split('.').last.to_i
                   else
                     destination_node
                   end
          buf[7] = source_node
          buf[8] = source_unit

          buf
        end

        def fins_tcp_cmnd_header
          header = ['FINS'.bytes.to_a, 0, 0, 0, 0xc, 0, 0, 0, 2, 0, 0, 0, 0].flatten
          header[19] = source_node == IOFINS_SOURCE_AUTO_NODE ? 0 : source_node
          header
        end

        def device_code_of(device)
          @@bit_codes ||= { nil => 0x30, '' => 0x30, 'W' => 0x31, 'H' => 0x32, 'A' => 0x33, 'T' => 0x09, 'C' => 0x09,
                            'D' => 0x02, 'E' => 0x0a, 'TK' => 0x06 }
          @@word_codes ||= { nil => 0xB0, '' => 0xB0, 'W' => 0xB1, 'H' => 0xB2, 'A' => 0xB3, 'TIM' => 0x89, 'CNT' => 0x89,
                             'D' => 0x82, 'E' => 0x98, 'DR' => 0xbc }
          if device.bit_device?
            @@bit_codes[device.suffix]
          else
            @@word_codes[device.suffix]
          end
        end

        def device_to_a(device)
          a = []
          a << device_code_of(device)
          a << int_to_a(device.channel, 2)
          a << (device.bit_device? ? (device.bit || 0) : 0)
          a.flatten
        end

        def int_to_a(value, size)
          a = []
          (size - 1).downto 0 do |i|
            a << ((value >> (i * 8)) & 0xff)
          end
          a
        end

        def to_int(a)
          v = 0
          a.each do |e|
            v <<= 8
            v += e
          end
          v
        end

        def dump_packet(packet)
          a =
            packet.map do |e|
              e.to_s(16).rjust(2, '0')
            end
          "[#{a.join(', ')}]"
        end
      end
    end
  end
end
