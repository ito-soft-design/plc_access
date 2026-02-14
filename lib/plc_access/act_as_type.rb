module PlcAccess

module ActAsType
  refine Array do

    def to_ushort
      pack("S*").unpack("S*")
    end

    def to_short
      pack("S*").unpack("s*")
    end

    def to_uint
      pack("S*").unpack("L*")
    end

    def to_int
      pack("S*").unpack("l*")
    end

    def to_float
      pack("S*").unpack("f*")
    end

    def as_ushort
      pack("S*").unpack("S*")
    end

    def as_short
      pack("s*").unpack("S*")
    end

    def as_uint
      pack("L*").unpack("S*")
    end

    def as_int
      pack("l*").unpack("S*")
    end

    def as_float
      pack("f*").unpack("S*")
    end

    def to_string length=nil, encoding=Encoding::UTF_8, endian: :little
      if length.respond_to?(:string_endian)
        endian = length.string_endian
        length = nil
      end
      if encoding.respond_to?(:string_endian)
        endian = encoding.string_endian
        encoding = Encoding::UTF_8
      end
      format = endian == :big ? "n*" : "v*"
      s = pack(format)
      if length
        s = s[0, length].delete("\000")
      end
      s.force_encoding(encoding).encode(Encoding::UTF_8)
    end
  
  end

  refine String do

    def as_ushort length=nil, encoding=Encoding::UTF_8, endian: :little
      if length.respond_to?(:string_endian)
        endian = length.string_endian
        length = nil
      end
      if encoding.respond_to?(:string_endian)
        endian = encoding.string_endian
        encoding = Encoding::UTF_8
      end
      format = endian == :big ? "n*" : "v*"
      a = self.encode(encoding).unpack(format)
      return a unless length

      s = (length + 1) / 2
      a += [0] * [s - a.length, 0].max
      a[0, s]
    end
  
  end
end

end
