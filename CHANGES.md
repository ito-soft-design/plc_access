# CHANGES

## 0.2.1

- Add byte order support for string/ushort conversion per PLC type (Mitsubishi: little-endian, Keyence/Omron: big-endian)
- Accept plc object in as_ushort/to_string to auto-detect byte order
- Allow Protocol#[]= to pad with zeros or truncate when array size differs from count
- Allow Protocol#[]= to accept arrays without specifying count

## 0.1.3

- Rename Array#as_string to Array#to_string
- Rename String#to_ushort to String#as_ushort

## 0.1.2

- Be able to access the type value that you want to get.
  - Use to_xxx for reading from the PLC.
  - Use as_xxx for writing to the PLC.
