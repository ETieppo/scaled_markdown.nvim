local font_binary_reader =
  require 'scaled_markdown.core.font.font_binary_reader'

local MISSING_GLYPH_INDEX = 0
local UINT16_RANGE = 65536
local ENCODING_COUNT_OFFSET = 2
local ENCODING_RECORDS_OFFSET = 4
local ENCODING_RECORD_LENGTH = 8
local UNICODE_PLATFORM = 0
local MACINTOSH_PLATFORM = 1
local WINDOWS_PLATFORM = 3
local WINDOWS_SYMBOL_ENCODING = 0
local SYMBOL_PRIVATE_USE_START = 0xF000
local BYTE_ENCODING_FORMAT = 0
local SEGMENT_MAPPING_FORMAT = 4
local TRIMMED_TABLE_FORMAT = 6
local SEGMENTED_COVERAGE_FORMAT = 12
---@type table<integer, integer>
local FORMAT_PRIORITY = {
  [SEGMENTED_COVERAGE_FORMAT] = 4,
  [SEGMENT_MAPPING_FORMAT] = 3,
  [TRIMMED_TABLE_FORMAT] = 2,
  [BYTE_ENCODING_FORMAT] = 1,
}

---@alias GlyphLookupProps fun(codepoint: integer): integer

---@class font_character_map
local font_character_map = {}

---@param data string
---@param offset integer
---@param codepoint integer
---@return integer
local function lookup_byte_encoding(data, offset, codepoint)
  if codepoint > 255 then return MISSING_GLYPH_INDEX end
  return font_binary_reader.read_uint8(data, offset + 6 + codepoint)
end

---@param data string
---@param offset integer
---@param codepoint integer
---@return integer
local function lookup_trimmed_table(data, offset, codepoint)
  local first_code = font_binary_reader.read_uint16(data, offset + 6)
  local entry_count = font_binary_reader.read_uint16(data, offset + 8)
  local entry_index = codepoint - first_code
  if entry_index < 0 or entry_index >= entry_count then
    return MISSING_GLYPH_INDEX
  end
  return font_binary_reader.read_uint16(data, offset + 10 + entry_index * 2)
end

---@param data string
---@param offset integer
---@param codepoint integer
---@return integer
local function lookup_segment_mapping(data, offset, codepoint)
  if codepoint >= UINT16_RANGE then return MISSING_GLYPH_INDEX end
  local segment_count =
    math.floor(font_binary_reader.read_uint16(data, offset + 6) / 2)
  local end_codes_offset = offset + 14
  local start_codes_offset = end_codes_offset + segment_count * 2 + 2
  local deltas_offset = start_codes_offset + segment_count * 2
  local range_offsets_offset = deltas_offset + segment_count * 2
  local low, high = 0, segment_count - 1
  while low <= high do
    local middle = math.floor((low + high) / 2)
    local end_code =
      font_binary_reader.read_uint16(data, end_codes_offset + middle * 2)
    if end_code < codepoint then
      low = middle + 1
    else
      high = middle - 1
    end
  end
  if low >= segment_count then return MISSING_GLYPH_INDEX end
  local start_code =
    font_binary_reader.read_uint16(data, start_codes_offset + low * 2)
  if codepoint < start_code then return MISSING_GLYPH_INDEX end
  local delta = font_binary_reader.read_uint16(data, deltas_offset + low * 2)
  local range_offset_position = range_offsets_offset + low * 2
  local range_offset =
    font_binary_reader.read_uint16(data, range_offset_position)
  if range_offset == 0 then return (codepoint + delta) % UINT16_RANGE end
  local glyph_index = font_binary_reader.read_uint16(
    data,
    range_offset_position + range_offset + (codepoint - start_code) * 2
  )
  if glyph_index == MISSING_GLYPH_INDEX then return MISSING_GLYPH_INDEX end
  return (glyph_index + delta) % UINT16_RANGE
end

---@param data string
---@param offset integer
---@param codepoint integer
---@return integer
local function lookup_segmented_coverage(data, offset, codepoint)
  local group_count = font_binary_reader.read_uint32(data, offset + 12)
  local low, high = 0, group_count - 1
  while low <= high do
    local middle = math.floor((low + high) / 2)
    local group_offset = offset + 16 + middle * 12
    local start_code = font_binary_reader.read_uint32(data, group_offset)
    local end_code = font_binary_reader.read_uint32(data, group_offset + 4)
    if codepoint < start_code then
      high = middle - 1
    elseif codepoint > end_code then
      low = middle + 1
    else
      return font_binary_reader.read_uint32(data, group_offset + 8)
        + codepoint
        - start_code
    end
  end
  return MISSING_GLYPH_INDEX
end

---@type table<integer, fun(data: string, offset: integer, codepoint: integer): integer>
local LOOKUP_BY_FORMAT = {
  [BYTE_ENCODING_FORMAT] = lookup_byte_encoding,
  [SEGMENT_MAPPING_FORMAT] = lookup_segment_mapping,
  [TRIMMED_TABLE_FORMAT] = lookup_trimmed_table,
  [SEGMENTED_COVERAGE_FORMAT] = lookup_segmented_coverage,
}

---@param platform_id integer
---@param format integer
---@return integer?
local function score_subtable(platform_id, format)
  local format_priority = FORMAT_PRIORITY[format]
  if not format_priority then return nil end
  if platform_id == WINDOWS_PLATFORM or platform_id == UNICODE_PLATFORM then
    return format_priority + 10
  end
  if platform_id == MACINTOSH_PLATFORM then return format_priority end
  return nil
end

---@param data string
---@param offset integer
---@return integer?
---@return boolean
local function select_subtable(data, offset)
  local encoding_count =
    font_binary_reader.read_uint16(data, offset + ENCODING_COUNT_OFFSET)
  ---@type integer?
  local best_offset = nil
  local best_score = -1
  local is_symbol = false
  for record_index = 0, encoding_count - 1 do
    local record_offset = offset
      + ENCODING_RECORDS_OFFSET
      + record_index * ENCODING_RECORD_LENGTH
    local platform_id = font_binary_reader.read_uint16(data, record_offset)
    local encoding_id = font_binary_reader.read_uint16(data, record_offset + 2)
    local subtable_offset = offset
      + font_binary_reader.read_uint32(data, record_offset + 4)
    local score = score_subtable(
      platform_id,
      font_binary_reader.read_uint16(data, subtable_offset)
    )
    if score and score > best_score then
      best_score = score
      best_offset = subtable_offset
      is_symbol = platform_id == WINDOWS_PLATFORM
        and encoding_id == WINDOWS_SYMBOL_ENCODING
    end
  end
  return best_offset, is_symbol
end

---@return GlyphLookupProps
local function build_missing_lookup()
  return function(_) return MISSING_GLYPH_INDEX end
end

---@param data string
---@param offset integer
---@return GlyphLookupProps
function font_character_map.create_lookup(data, offset)
  local subtable_offset, is_symbol = select_subtable(data, offset)
  if not subtable_offset then return build_missing_lookup() end
  local lookup =
    LOOKUP_BY_FORMAT[font_binary_reader.read_uint16(data, subtable_offset)]
  ---@type table<integer, integer>
  local glyph_index_by_codepoint = {}
  return function(codepoint)
    local cached_index = glyph_index_by_codepoint[codepoint]
    if cached_index then return cached_index end
    local glyph_index = lookup(data, subtable_offset, codepoint)
    if glyph_index == MISSING_GLYPH_INDEX and is_symbol then
      glyph_index =
        lookup(data, subtable_offset, SYMBOL_PRIVATE_USE_START + codepoint)
    end
    glyph_index_by_codepoint[codepoint] = glyph_index
    return glyph_index
  end
end

return font_character_map
