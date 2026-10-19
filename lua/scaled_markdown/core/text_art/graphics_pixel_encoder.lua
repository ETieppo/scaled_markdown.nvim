local color_math = require 'scaled_markdown.core.highlight.color_math'

local MAX_CHANNEL_VALUE = 255
local TRANSPARENT_PIXEL = '\0\0\0\0'

---@class graphics_pixel_encoder
local graphics_pixel_encoder = {}

---@param start_color string
---@param end_color string
---@param ink_width integer
---@return integer[][]
local function build_column_colors(start_color, end_color, ink_width)
  local start_rgb = color_math.hex_to_rgb(start_color)
  local end_rgb = color_math.hex_to_rgb(end_color)
  ---@type integer[][]
  local column_colors = {}
  for column = 1, ink_width do
    local ratio = ink_width > 1 and (column - 1) / (ink_width - 1) or 0
    ---@type integer[]
    local rgb = {}
    for channel_index = 1, 3 do
      rgb[channel_index] = math.floor(
        start_rgb[channel_index]
          + (end_rgb[channel_index] - start_rgb[channel_index]) * ratio
          + 0.5
      )
    end
    column_colors[column] = rgb
  end
  return column_colors
end

---@param bitmap CoverageBitmapProps
---@param ink_width integer
---@param image_width integer
---@param image_height integer
---@param start_color string
---@param end_color string
---@return string
function graphics_pixel_encoder.encode_rgba(
  bitmap,
  ink_width,
  image_width,
  image_height,
  start_color,
  end_color
)
  local column_colors = build_column_colors(start_color, end_color, ink_width)
  local transparent_row = TRANSPARENT_PIXEL:rep(image_width)
  ---@type string[]
  local rows = {}
  for row = 0, image_height - 1 do
    if row >= bitmap.height then
      rows[row + 1] = transparent_row
    else
      ---@type string[]
      local pixels = {}
      local row_base = row * bitmap.width
      for column = 1, image_width do
        local coverage = column <= ink_width
            and bitmap.values[row_base + column]
          or 0
        local alpha = math.floor(coverage * MAX_CHANNEL_VALUE + 0.5)
        if alpha > 0 then
          local rgb = column_colors[column]
          pixels[column] = string.char(rgb[1], rgb[2], rgb[3], alpha)
        else
          pixels[column] = TRANSPARENT_PIXEL
        end
      end
      rows[row + 1] = table.concat(pixels)
    end
  end
  return table.concat(rows)
end

return graphics_pixel_encoder
