local font_binary_reader =
  require 'scaled_markdown.core.font.font_binary_reader'

local SUPPORTED_TABLE_VERSION = 0
local SUBTABLE_COUNT_OFFSET = 2
local SUBTABLES_OFFSET = 4
local SUBTABLE_LENGTH_OFFSET = 2
local SUBTABLE_COVERAGE_OFFSET = 4
local PAIR_COUNT_OFFSET = 6
local PAIRS_OFFSET = 14
local PAIR_RECORD_LENGTH = 6
local ORDERED_PAIR_FORMAT = 0
local FORMAT_DIVISOR = 256
local HORIZONTAL_FLAG = 1
local MINIMUM_FLAG = 2
local CROSS_STREAM_FLAG = 4
local PAIR_KEY_FACTOR = 65536
local NO_KERNING = 0

---@alias KerningLookupProps fun(left_glyph_index: integer, right_glyph_index: integer): number

---@class font_kerning_table
local font_kerning_table = {}

---@param coverage integer
---@return boolean
local function is_supported_subtable(coverage)
  return math.floor(coverage / FORMAT_DIVISOR) == ORDERED_PAIR_FORMAT
    and font_binary_reader.has_flag(coverage, HORIZONTAL_FLAG)
    and not font_binary_reader.has_flag(coverage, MINIMUM_FLAG)
    and not font_binary_reader.has_flag(coverage, CROSS_STREAM_FLAG)
end

---@param data string
---@param subtable_offset integer
---@param kerning_by_pair table<integer, number>
local function collect_pairs(data, subtable_offset, kerning_by_pair)
  local pair_count =
    font_binary_reader.read_uint16(data, subtable_offset + PAIR_COUNT_OFFSET)
  for pair_index = 0, pair_count - 1 do
    local pair_offset = subtable_offset
      + PAIRS_OFFSET
      + pair_index * PAIR_RECORD_LENGTH
    local pair_key = font_binary_reader.read_uint16(data, pair_offset)
        * PAIR_KEY_FACTOR
      + font_binary_reader.read_uint16(data, pair_offset + 2)
    kerning_by_pair[pair_key] = (kerning_by_pair[pair_key] or NO_KERNING)
      + font_binary_reader.read_int16(data, pair_offset + 4)
  end
end

---@param data string
---@param table_offset integer
---@return table<integer, number>
local function read_pairs(data, table_offset)
  ---@type table<integer, number>
  local kerning_by_pair = {}
  if
    font_binary_reader.read_uint16(data, table_offset)
    ~= SUPPORTED_TABLE_VERSION
  then
    return kerning_by_pair
  end
  local subtable_count =
    font_binary_reader.read_uint16(data, table_offset + SUBTABLE_COUNT_OFFSET)
  local subtable_offset = table_offset + SUBTABLES_OFFSET
  for _ = 1, subtable_count do
    local coverage = font_binary_reader.read_uint16(
      data,
      subtable_offset + SUBTABLE_COVERAGE_OFFSET
    )
    if is_supported_subtable(coverage) then
      collect_pairs(data, subtable_offset, kerning_by_pair)
    end
    subtable_offset = subtable_offset
      + font_binary_reader.read_uint16(
        data,
        subtable_offset + SUBTABLE_LENGTH_OFFSET
      )
  end
  return kerning_by_pair
end

---@param data string
---@param kerning_table FontTableProps
---@return KerningLookupProps
function font_kerning_table.create_lookup(data, kerning_table)
  local kerning_by_pair = kerning_table
      and read_pairs(data, kerning_table.offset)
    or {}
  return function(left_glyph_index, right_glyph_index)
    return kerning_by_pair[left_glyph_index * PAIR_KEY_FACTOR + right_glyph_index]
      or NO_KERNING
  end
end

return font_kerning_table
