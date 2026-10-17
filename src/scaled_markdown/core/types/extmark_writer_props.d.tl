local record ExtmarkWriterProps
  set_extmark: function(
    row: integer,
    col: integer,
    extmark_options: vim.ExtmarkOptionsProps
  ): integer
end

return ExtmarkWriterProps
