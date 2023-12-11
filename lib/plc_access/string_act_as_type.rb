module PlcAccess
  module StringActAsType
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
  