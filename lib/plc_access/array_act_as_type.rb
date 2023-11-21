module PlcAccess
module ArrayActAsType
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

  end
end
end
