local type CaptureProps = require 'scaled_markdown.core.types.capture_props'

local record capture_dto_builder
end

function capture_dto_builder.build(
  buf: integer,
  capture_name: string,
  node: vim.TSNodeProps
): CaptureProps
  local start_row, start_col, end_row, end_col = node:range()
  return {
    name = capture_name,
    node = node,
    start_row = start_row,
    start_col = start_col,
    end_row = end_row,
    end_col = end_col,
    text = vim.treesitter.get_node_text(node, buf),
  }
end

return capture_dto_builder
