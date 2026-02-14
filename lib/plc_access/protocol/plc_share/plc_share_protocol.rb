# frozen_string_literal: true

# The MIT License (MIT)
#
# Copyright (c) 2025 ITO SOFT DESIGN Inc.
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
    module PlcShare
      class PlcShareProtocol < PlcAccess::Protocol::Keyence::KvProtocol
        attr_accessor :device_type

        def initialize(options = {})
          super
          @socket = nil
          @host = options[:host] || '192.168.0.10'
          @port = options[:port] || 10000
          self.device_type = options[:device_type] if options[:device_type]
        end

        # Device type
        #   :kv  Keyence device
        #   :fx  Mitsubishi Fx device
        #   :q   Mitsubishi Q/L device
        #   :omron   Omron device
        def device_type= type
          @device_type = type
        end

        def string_endian
          case @device_type
          when :fx, :q
            :little
          else
            :big
          end
        end

        private

        def device_class
          case @device_type
          when :kv
            PlcAccess::Protocol::Keyence::KvDevice
          when :fx
            PlcAccess::Protocol::Mitsubishi::FxDevice
          when :q
            PlcAccess::Protocol::Mitsubishi::QDevice
          when :omron
            PlcAccess::Protocol::Omron::OmronDevice
          else
            PlcAccess::Protocol::Keyence::KvDevice
          end
        end
      end
    end
  end
end

