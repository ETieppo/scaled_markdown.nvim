local HEX_COLOR_PATTERN = '^#(%x%x)(%x%x)(%x%x)$'
local HEX_COLOR_FORMAT = '#%02x%02x%02x'
---@type integer[]
local XTERM_CUBE_LEVELS = { 0, 95, 135, 175, 215, 255 }
local XTERM_CUBE_FIRST_INDEX = 16
local XTERM_GRAY_FIRST_INDEX = 232
local XTERM_GRAY_COUNT = 24
local XTERM_GRAY_FIRST_LEVEL = 8
local XTERM_GRAY_STEP = 10

---@class color_math
local color_math = {}

---@param hex_color string
---@return integer[]
function color_math.hex_to_rgb(hex_color)
  local red, green, blue = hex_color:match(HEX_COLOR_PATTERN)
  if not red then
    error(('invalid hex color: %s'):format(tostring(hex_color)))
  end
  return {
    math.floor(tonumber(red, 16)),
    math.floor(tonumber(green, 16)),
    math.floor(tonumber(blue, 16)),
  }
end

---@param rgb_color integer[]
---@return string
function color_math.rgb_to_hex(rgb_color)
  return HEX_COLOR_FORMAT:format(rgb_color[1], rgb_color[2], rgb_color[3])
end

---@param a integer[]
---@param b integer[]
---@param t number
---@return integer[]
local function lerp_rgb(a, b, t)
  ---@type integer[]
  local out = {}
  for channel_index = 1, 3 do
    local value = a[channel_index] + (b[channel_index] - a[channel_index]) * t
    out[channel_index] = math.floor(value + 0.5)
  end
  return out
end

---@param colors string[]
---@param ratio number
---@return string
function color_math.interpolate_hex(colors, ratio)
  ---@type string[]
  local stops = {}
  for _, color in ipairs(colors or {}) do
    stops[#stops + 1] = color
  end

  if #stops == 1 then return stops[1] end

  ratio = math.max(0, math.min(1, ratio))
  local segment_count = #stops - 1
  local scaled = ratio * segment_count
  local index = math.floor(scaled) + 1

  if index > segment_count then index = segment_count end

  local local_t = scaled - (index - 1)
  local start_rgb = color_math.hex_to_rgb(stops[index])
  local end_rgb = color_math.hex_to_rgb(stops[index + 1])

  return color_math.rgb_to_hex(lerp_rgb(start_rgb, end_rgb, local_t))
end

---@param channel integer
---@return integer
local function nearest_cube_level_index(channel)
  local best_index = 1
  for level_index, level in ipairs(XTERM_CUBE_LEVELS) do
    if
      math.abs(level - channel)
      < math.abs(XTERM_CUBE_LEVELS[best_index] - channel)
    then
      best_index = level_index
    end
  end
  return best_index
end

---@param a integer[]
---@param b integer[]
---@return integer
local function squared_distance(a, b)
  local distance = 0
  for channel_index = 1, 3 do
    distance = distance + (a[channel_index] - b[channel_index]) ^ 2
  end
  return math.floor(distance)
end

---@param rgb_color integer[]
---@return integer
function color_math.nearest_xterm_index(rgb_color)
  ---@type integer[]
  local cube_indices = {}
  ---@type integer[]
  local cube_color = {}
  for channel_index = 1, 3 do
    cube_indices[channel_index] =
      nearest_cube_level_index(rgb_color[channel_index])
    cube_color[channel_index] = XTERM_CUBE_LEVELS[cube_indices[channel_index]]
  end
  local cube_index = XTERM_CUBE_FIRST_INDEX
    + 36 * (cube_indices[1] - 1)
    + 6 * (cube_indices[2] - 1)
    + (cube_indices[3] - 1)
  local average = (rgb_color[1] + rgb_color[2] + rgb_color[3]) / 3
  local gray_step = math.floor(
    math.min(
      XTERM_GRAY_COUNT - 1,
      math.max(0, (average - XTERM_GRAY_FIRST_LEVEL) / XTERM_GRAY_STEP + 0.5)
    )
  )
  local gray_level = XTERM_GRAY_FIRST_LEVEL + gray_step * XTERM_GRAY_STEP
  if
    squared_distance(rgb_color, { gray_level, gray_level, gray_level })
    < squared_distance(rgb_color, cube_color)
  then
    return XTERM_GRAY_FIRST_INDEX + gray_step
  end
  return cube_index
end

return color_math
