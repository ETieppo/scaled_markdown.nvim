local CORE_CONSTANTS = require 'scaled_markdown.core.constants'

local record viewport_range
end

function viewport_range.resolve(win: integer, buf: integer): integer, integer
  local top_row, bottom_row = vim.api.nvim_win_call(
    win,
    function(): integer, integer
      return vim.fn.line 'w0' - 1, vim.fn.line 'w$'
    end
  )
  local line_count = vim.api.nvim_buf_line_count(buf)
  local start_row = math.max(0, top_row - CORE_CONSTANTS.VIEWPORT_MARGIN_LINES)
  local end_row =
    math.min(line_count, bottom_row + CORE_CONSTANTS.VIEWPORT_MARGIN_LINES)
  return start_row, end_row
end

return viewport_range
