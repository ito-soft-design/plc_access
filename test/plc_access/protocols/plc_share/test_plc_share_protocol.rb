# frozen_string_literal: true

require 'test/unit'
require 'plc_access'

include PlcAccess::Protocol::Keyence
include PlcAccess::Protocol::Mitsubishi
include PlcAccess::Protocol::Omron
include PlcAccess::Protocol::PlcShare

class TestPlcShareProtocol < Test::Unit::TestCase
  attr_reader :running

  def test_device_type_kv
    plc = PlcShareProtocol.new device_type: :kv
    d = plc.device_by_name 'MR0'
    assert_equal KvDevice, d.class
  end

  def test_device_type_fx
    plc = PlcShareProtocol.new device_type: :fx
    d = plc.device_by_name 'M0'
    assert_equal FxDevice, d.class
  end

  def test_device_type_q
    plc = PlcShareProtocol.new device_type: :q
    d = plc.device_by_name 'M0'
    assert_equal QDevice, d.class
  end

  def test_device_type_omron
    plc = PlcShareProtocol.new device_type: :omron
    d = plc.device_by_name '0.0'
    assert_equal OmronDevice, d.class
  end

end
