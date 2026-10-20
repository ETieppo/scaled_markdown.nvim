local bit = require 'bit'

local SEQUENCE_START = '\27P0;1;0q'
local SEQUENCE_END = '\27\\'
local RASTER_ATTRIBUTES_FORMAT = '"1;1;%d;%d'
local COLOR_DEFINITION_FORMAT = '#%d;2;%d;%d;%d'
local COLOR_SELECTION_FORMAT = '#%d'
local REPEAT_FORMAT = '!%d%s'
local CARRIAGE_RETURN = '$'
local NEXT_BAND = '-'
local BAND_HEIGHT = 6
local SIXEL_CHARACTER_OFFSET = 63
local MIN_REPEAT_LENGTH = 4
local MAX_CHANNEL_VALUE = 255
local MAX_PERCENT = 100
local TRANSPARENT_INDEX = 0

---@class sixel_encoder
local sixel_encoder = {}

---@param channel_value integer
---@return integer
local function to_percent(channel_value)
  return math.floor(channel_value * MAX_PERCENT / MAX_CHANNEL_VALUE + 0.5)
end

---@param parts string[]
---@param character string
---@param count integer
local function append_run(parts, character, count)
  if count >= MIN_REPEAT_LENGTH then
    parts[#parts + 1] = REPEAT_FORMAT:format(count, character)
  else
    parts[#parts + 1] = character:rep(count)
  end
end

---@param parts string[]
---@param column_bits table<integer, integer>
---@param last_column integer
local function append_color_row(parts, column_bits, last_column)
  local run_character = nil
  local run_length = 0
  for column = 1, last_column do
    local character =
      string.char(SIXEL_CHARACTER_OFFSET + (column_bits[column] or 0))
    if character == run_character then
      run_length = run_length + 1
    else
      if run_character then append_run(parts, run_character, run_length) end
      run_character, run_length = character, 1
    end
  end
  if run_character then append_run(parts, run_character, run_length) end
end

---@param pixel_indices integer[]
---@param width integer
---@param height integer
---@param band_top integer
---@return table<integer, table<integer, integer>>, table<integer, integer>
local function collect_band(pixel_indices, width, height, band_top)
  ---@type table<integer, table<integer, integer>>
  local bits_by_index = {}
  ---@type table<integer, integer>
  local last_column_by_index = {}
  for band_row = 0, math.min(BAND_HEIGHT, height - band_top) - 1 do
    local row_base = (band_top + band_row) * width
    local row_bit = bit.lshift(1, band_row)
    for column = 1, width do
      local index = pixel_indices[row_base + column]
      if index ~= TRANSPARENT_INDEX then
        local column_bits = bits_by_index[index]
        if not column_bits then
          column_bits = {}
          bits_by_index[index] = column_bits
        end
        column_bits[column] = bit.bor(column_bits[column] or 0, row_bit)
        last_column_by_index[index] =
          math.max(last_column_by_index[index] or 0, column)
      end
    end
  end
  return bits_by_index, last_column_by_index
end

---@param pixel_indices integer[]
---@param palette integer[][]
---@return string[]
local function build_color_definitions(pixel_indices, palette)
  ---@type table<integer, boolean>
  local used_indices = {}
  for _, index in ipairs(pixel_indices) do
    if index ~= TRANSPARENT_INDEX then used_indices[index] = true end
  end
  ---@type string[]
  local definitions = {}
  for index, rgb in ipairs(palette) do
    if used_indices[index] then
      definitions[#definitions + 1] = COLOR_DEFINITION_FORMAT:format(
        index - 1,
        to_percent(rgb[1]),
        to_percent(rgb[2]),
        to_percent(rgb[3])
      )
    end
  end
  return definitions
end

---@param pixel_indices integer[]
---@param width integer
---@param height integer
---@param palette integer[][]
---@return string
function sixel_encoder.encode(pixel_indices, width, height, palette)
  ---@type string[]
  local parts =
    { SEQUENCE_START, RASTER_ATTRIBUTES_FORMAT:format(width, height) }
  vim.list_extend(parts, build_color_definitions(pixel_indices, palette))
  for band_top = 0, height - 1, BAND_HEIGHT do
    local bits_by_index, last_column_by_index =
      collect_band(pixel_indices, width, height, band_top)
    local band_indices = vim.tbl_keys(bits_by_index)
    table.sort(band_indices)
    for _, index in ipairs(band_indices) do
      parts[#parts + 1] = COLOR_SELECTION_FORMAT:format(index - 1)
      append_color_row(parts, bits_by_index[index], last_column_by_index[index])
      parts[#parts + 1] = CARRIAGE_RETURN
    end
    parts[#parts + 1] = NEXT_BAND
  end
  parts[#parts + 1] = SEQUENCE_END
  return table.concat(parts)
end

return sixel_encoder
