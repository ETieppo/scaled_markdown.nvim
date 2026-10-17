local record BorderCharsetProps
  TOP_LEFT: string
  TOP_RIGHT: string
  BOTTOM_LEFT: string
  BOTTOM_RIGHT: string
  HORIZONTAL: string
  VERTICAL: string
  TOP_JUNCTION: string
  BOTTOM_JUNCTION: string
  LEFT_JUNCTION: string
  RIGHT_JUNCTION: string
  CROSS_JUNCTION: string
end

local BORDER_CHARSET <const>: BorderCharsetProps = {
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
