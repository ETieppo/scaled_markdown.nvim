---@class BorderCharsetProps
---@field TOP_LEFT string
---@field TOP_RIGHT string
---@field BOTTOM_LEFT string
---@field BOTTOM_RIGHT string
---@field HORIZONTAL string
---@field VERTICAL string
---@field TOP_JUNCTION string
---@field BOTTOM_JUNCTION string
---@field LEFT_JUNCTION string
---@field RIGHT_JUNCTION string
---@field CROSS_JUNCTION string

---@type BorderCharsetProps
local BORDER_CHARSET = {
  TOP_LEFT = '╭',
  TOP_RIGHT = '╮',
  BOTTOM_LEFT = '╰',
  BOTTOM_RIGHT = '╯',
  HORIZONTAL = '─',
  VERTICAL = '│',
  TOP_JUNCTION = '┬',
  BOTTOM_JUNCTION = '┴',
  LEFT_JUNCTION = '├',
  RIGHT_JUNCTION = '┤',
  CROSS_JUNCTION = '┼',
}

return BORDER_CHARSET
