local record ffi
  record C
    ioctl: function(integer, integer, any): integer
    open: function(string, integer): integer
    close: function(integer): integer
  end

  cdef: function(string)
  new: function(string): any
  typeof: function(string): any
end

return ffi
