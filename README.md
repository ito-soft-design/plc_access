# PlcAccess

PlcAccess is library to make connection with PLCs.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'plc_access'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install plc_access

## Usage


Mitsubishi MC Protocol:

```
require 'plc_access'

plc = PlcAccess::Protocol::Mitsubishi::McProtocol.new host:"192.168.0.10"

plc["M0"] = true
plc["M0"]         # => true
plc["M0", 10]     # => [true, false, ..., false]

plc["D0"] = 123
plc["D0"]       # => 123
plc["D0", 10] = [0, 1, 2, ..., 9]
plc["D0".."D9"]   => [0, 1, 2, ..., 9]
```

Keyence PLCs:

```
require 'plc_access'

plc = PlcAccess::Protocol::Keyence::KvProtocol.new host:"192.168.0.10"

plc["MR0"] = true
plc["MR0"]         # => true
plc["MR0", 10]     # => [true, false, ..., false]

plc["DM0"] = 123
plc["DM0"]       # => 123
plc["DM0", 10] = [0, 1, 2, ..., 9]
plc["DM0".."DM9"]   => [0, 1, 2, ..., 9]
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ito-soft-design/plc_access. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/ito-soft-design/plc_access/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the PlcAccess project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/ito-soft-design/plc_access/blob/master/CODE_OF_CONDUCT.md).
