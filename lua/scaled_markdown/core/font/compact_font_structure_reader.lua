local font_binary_reader =
  require 'scaled_markdown.core.font.font_binary_reader'

local EMPTY_INDEX_LENGTH = 2
local INDEX_HEADER_LENGTH = 3
local ESCAPE_OPERATOR = 12
local ESCAPED_OPERATOR_BASE = 1200
local LAST_OPERATOR = 21
local SHORT_INTEGER_PREFIX = 28
local LONG_INTEGER_PREFIX = 29
local REAL_NUMBER_PREFIX = 30
local SMALL_INTEGER_FIRST = 32
local SMALL_INTEGER_LAST = 246
local SMALL_INTEGER_BIAS = 139
local POSITIVE_INTEGER_LAST = 250
local NEGATIVE_INTEGER_LAST = 254
local POSITIVE_INTEGER_FIRST = 247
local NEGATIVE_INTEGER_FIRST = 251
local TWO_BYTE_INTEGER_BIAS = 108
local BYTE_RANGE = 256
local REAL_END_NIBBLE = 15
---@type table<integer, string>
local REAL_NIBBLE_TEXT = {
  [10] = '.',
  [11] = 'e',
  [12] = 'e-',
  [14] = '-',
}

---@alias CompactFontDictProps table<integer, number[]>

---@class compact_font_structure_reader
local compact_font_structure_reader = {}

---@param data string
---@param index CompactFontIndexProps
---@param item_position integer
---@return integer
local function read_offset(data, index, item_position)
  return font_binary_reader.read_uint_of_size(
    data,
    index.offsets_start + item_position * index.offset_size,
    index.offset_size
  )
end

---@param data string
---@param offset integer
---@return CompactFontIndexProps
function compact_font_structure_reader.read_index(data, offset)
  local count = font_binary_reader.read_uint16(data, offset)
  if count == 0 then
    return {
      count = 0,
      offset_size = 0,
      offsets_start = offset,
      data_base = offset,
      end_offset = offset + EMPTY_INDEX_LENGTH,
    }
  end
  local offset_size = font_binary_reader.read_uint8(data, offset + 2)
  local offsets_start = offset + INDEX_HEADER_LENGTH
  ---@type CompactFontIndexProps
  local index = {
    count = count,
    offset_size = offset_size,
    offsets_start = offsets_start,
    data_base = offsets_start + (count + 1) * offset_size - 1,
  }
  index.end_offset = index.data_base + read_offset(data, index, count)
  return index
end

---@param data string
---@param index CompactFontIndexProps
---@param item_index integer
---@return integer?
---@return integer?
function compact_font_structure_reader.item_range(data, index, item_index)
  if item_index < 0 or item_index >= index.count then return nil, nil end
  return index.data_base + read_offset(data, index, item_index),
    index.data_base + read_offset(data, index, item_index + 1)
end

---@param data string
---@param offset integer
---@return number
---@return integer
local function read_real_number(data, offset)
  ---@type string[]
  local characters = {}
  while true do
    local packed_byte = font_binary_reader.read_uint8(data, offset)
    offset = offset + 1
    for _, nibble in ipairs { math.floor(packed_byte / 16), packed_byte % 16 } do
      if nibble == REAL_END_NIBBLE then
        return tonumber(table.concat(characters)) or 0, offset
      end
      characters[#characters + 1] = REAL_NIBBLE_TEXT[nibble] or tostring(nibble)
    end
  end
end

---@param data string
---@param offset integer
---@return number?
---@return integer
local function read_operand(data, offset)
  local first_byte = font_binary_reader.read_uint8(data, offset)
  if first_byte >= SMALL_INTEGER_FIRST and first_byte <= SMALL_INTEGER_LAST then
    return first_byte - SMALL_INTEGER_BIAS, offset + 1
  end
  if
    first_byte >= POSITIVE_INTEGER_FIRST
    and first_byte <= POSITIVE_INTEGER_LAST
  then
    return (first_byte - POSITIVE_INTEGER_FIRST) * BYTE_RANGE
      + font_binary_reader.read_uint8(data, offset + 1)
      + TWO_BYTE_INTEGER_BIAS,
      offset + 2
  end
  if
    first_byte >= NEGATIVE_INTEGER_FIRST
    and first_byte <= NEGATIVE_INTEGER_LAST
  then
    return -(first_byte - NEGATIVE_INTEGER_FIRST) * BYTE_RANGE
      - font_binary_reader.read_uint8(data, offset + 1)
      - TWO_BYTE_INTEGER_BIAS,
      offset + 2
  end
  if first_byte == SHORT_INTEGER_PREFIX then
    return font_binary_reader.read_int16(data, offset + 1), offset + 3
  end
  if first_byte == LONG_INTEGER_PREFIX then
    return font_binary_reader.read_int32(data, offset + 1), offset + 5
  end
  if first_byte == REAL_NUMBER_PREFIX then
    return read_real_number(data, offset + 1)
  end
  return nil, offset + 1
end

---@param data string
---@param start_offset integer
---@param end_offset integer
---@return CompactFontDictProps
function compact_font_structure_reader.read_dict(data, start_offset, end_offset)
  ---@type CompactFontDictProps
  local dict = {}
  ---@type number[]
  local operands = {}
  local offset = start_offset
  while offset < end_offset do
    local first_byte = font_binary_reader.read_uint8(data, offset)
    if first_byte <= LAST_OPERATOR then
      local operator = first_byte
      offset = offset + 1
      if first_byte == ESCAPE_OPERATOR then
        operator = ESCAPED_OPERATOR_BASE
          + font_binary_reader.read_uint8(data, offset)
        offset = offset + 1
      end
      dict[operator] = operands
      operands = {}
    else
      ---@type number?
      local operand
      operand, offset = read_operand(data, offset)
      if operand then operands[#operands + 1] = operand end
    end
  end
  return dict
end

return compact_font_structure_reader
