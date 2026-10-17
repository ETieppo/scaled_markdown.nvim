local record CaptureProps
  name: string
  node: vim.TSNodeProps
  start_row: integer
  start_col: integer
  end_row: integer
  end_col: integer
  text: string
end

return CaptureProps
