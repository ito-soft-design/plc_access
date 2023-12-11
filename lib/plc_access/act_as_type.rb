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

    def as_string length=nil, encoding=Encoding::UTF_8
      s = pack("v*")
      if length
        s = s[0, length].delete("\000")
      end
      s.force_encoding(encoding).encode(Encoding::UTF_8)
    end
  
  end

  refine String do

    def to_ushort length=nil, encoding=Encoding::UTF_8
      a = self.encode(encoding).unpack("v*")
      return a unless length
      
      s = (length + 1) / 2
      a += [0] * [s - a.length, 0].max
      a[0, s]
    end
  
  end
end

end
