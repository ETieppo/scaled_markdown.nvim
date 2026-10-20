local color_math = require 'scaled_markdown.core.highlight.color_math'
local sixel_encoder = require 'scaled_markdown.core.terminal.sixel_encoder'

local GRADIENT_LEVELS = 32
local COVERAGE_LEVELS = 8
local TRANSPARENT_INDEX = 0

---@class graphics_sixel_builder
local graphics_sixel_builder = {}

---@param background_rgb integer[]
---@param foreground_rgb integer[]
---@param coverage number
---@return integer[]
local function blend(background_rgb, foreground_rgb, coverage)
  ---@type integer[]
  local rgb = {}
  for channel_index = 1, 3 do
    rgb[channel_index] = math.floor(
      background_rgb[channel_index]
        + (foreground_rgb[channel_index] - background_rgb[channel_index]) * coverage
        + 0.5
    )
  end
  return rgb
end

---@param gradient_colors string[]
---@param background_color string
---@return integer[][]
local function build_palette(gradient_colors, background_color)
  local background_rgb = color_math.hex_to_rgb(background_color)
  ---@type integer[][]
  local palette = {}
  for gradient_level = 1, GRADIENT_LEVELS do
    local foreground_rgb = color_math.hex_to_rgb(
      color_math.interpolate_hex(
        gradient_colors,
        (gradient_level - 1) / (GRADIENT_LEVELS - 1)
      )
    )
    for coverage_level = 1, COVERAGE_LEVELS do
      palette[#palette + 1] =
        blend(background_rgb, foreground_rgb, coverage_level / COVERAGE_LEVELS)
    end
  end
  return palette
end

---@param ink_width integer
---@return integer[]
local function build_column_levels(ink_width)
  ---@type integer[]
  local column_levels = {}
  for column = 1, ink_width do
    local ratio = ink_width > 1 and (column - 1) / (ink_width - 1) or 0
    column_levels[column] = math.floor(ratio * (GRADIENT_LEVELS - 1) + 0.5)
  end
  return column_levels
end

---@param bitmap CoverageBitmapProps
---@param ink_width integer
---@param image_width integer
---@param image_height integer
---@param gradient_colors string[]
---@param background_color string
---@return string
function graphics_sixel_builder.build(
  bitmap,
  ink_width,
  image_width,
  image_height,
  gradient_colors,
  background_color
)
  local column_levels = build_column_levels(ink_width)
  ---@type integer[]
  local pixel_indices = {}
  for row = 0, image_height - 1 do
    local row_base = row * image_width
    local bitmap_base = row * bitmap.width
    for column = 1, image_width do
      local coverage = (row < bitmap.height and column <= ink_width)
          and bitmap.values[bitmap_base + column]
        or 0
      local coverage_level = math.floor(coverage * COVERAGE_LEVELS + 0.5)
      pixel_indices[row_base + column] = coverage_level == 0
          and TRANSPARENT_INDEX
        or column_levels[column] * COVERAGE_LEVELS + coverage_level
    end
  end
  return sixel_encoder.encode(
    pixel_indices,
    image_width,
    image_height,
    build_palette(gradient_colors, background_color)
  )
end

return graphics_sixel_builder
