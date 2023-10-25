# frozen_string_literal: true

root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
d = File.join(root, 'lib')
$LOAD_PATH.unshift d unless $LOAD_PATH.include? d
d = File.join(root, 'plc')
$LOAD_PATH.unshift d unless $LOAD_PATH.include? d
