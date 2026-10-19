local font_binary_reader =
  require 'scaled_markdown.core.font.font_binary_reader'

local RECORD_COUNT_OFFSET = 2
local STRING_STORAGE_OFFSET = 4
local RECORDS_OFFSET = 6
local RECORD_LENGTH = 12
local UNICODE_PLATFORM = 0
local MACINTOSH_PLATFORM = 1
local WINDOWS_PLATFORM = 3
local WINDOWS_ENGLISH_LANGUAGE = 0x0409
local MACINTOSH_ENGLISH_LANGUAGE = 0
local FAMILY_NAME_ID = 1
local STYLE_NAME_ID = 2
local TYPOGRAPHIC_FAMILY_NAME_ID = 16
local TYPOGRAPHIC_STYLE_NAME_ID = 17
local HIGH_SURROGATE_START = 0xD800
local LOW_SURROGATE_START = 0xDC00
local SURROGATE_END = 0xDFFF
local SURROGATE_RANGE = 0x400
local SUPPLEMENTARY_PLANE_START = 0x10000

---@class NameRecordProps
---@field platform_id integer
---@field language_id integer
---@field name_id integer
---@field value string

---@class font_name_reader
local font_name_reader = {}

---@param encoded string
---@return string
local function decode_utf16(encoded)
  ---@type string[]
  local characters = {}
  local offset = 0
  while offset + 1 < #encoded do
    ---@type integer?
    local code_unit = font_binary_reader.read_uint16(encoded, offset)
    offset = offset + 2
    if
      code_unit >= HIGH_SURROGATE_START
      and code_unit < LOW_SURROGATE_START
      and offset + 1 < #encoded
    then
      local low_unit = font_binary_reader.read_uint16(encoded, offset)
      offset = offset + 2
      code_unit = SUPPLEMENTARY_PLANE_START
        + (code_unit - HIGH_SURROGATE_START) * SURROGATE_RANGE
        + (low_unit - LOW_SURROGATE_START)
    elseif code_unit >= HIGH_SURROGATE_START and code_unit <= SURROGATE_END then
      code_unit = nil
    end
    if code_unit then
      characters[#characters + 1] = vim.fn.nr2char(code_unit)
    end
  end
  return table.concat(characters)
end

---@param platform_id integer
---@param encoded string
---@return string
local function decode_value(platform_id, encoded)
  if platform_id == MACINTOSH_PLATFORM then return encoded end
  return decode_utf16(encoded)
end

---@param data string
---@param offset integer
---@return NameRecordProps[]
local function read_records(data, offset)
  local record_count =
    font_binary_reader.read_uint16(data, offset + RECORD_COUNT_OFFSET)
  local storage_offset = offset
    + font_binary_reader.read_uint16(data, offset + STRING_STORAGE_OFFSET)
  ---@type NameRecordProps[]
  local records = {}
  for record_index = 0, record_count - 1 do
    local record_offset = offset + RECORDS_OFFSET + record_index * RECORD_LENGTH
    local platform_id = font_binary_reader.read_uint16(data, record_offset)
    if
      platform_id == UNICODE_PLATFORM
      or platform_id == MACINTOSH_PLATFORM
      or platform_id == WINDOWS_PLATFORM
    then
      local length = font_binary_reader.read_uint16(data, record_offset + 8)
      local value_offset = storage_offset
        + font_binary_reader.read_uint16(data, record_offset + 10)
      records[#records + 1] = {
        platform_id = platform_id,
        language_id = font_binary_reader.read_uint16(data, record_offset + 4),
        name_id = font_binary_reader.read_uint16(data, record_offset + 6),
        value = decode_value(
          platform_id,
          data:sub(value_offset + 1, value_offset + length)
        ),
      }
    end
  end
  return records
end

---@param name_record NameRecordProps
---@return boolean
local function is_english(name_record)
  if name_record.platform_id == WINDOWS_PLATFORM then
    return name_record.language_id == WINDOWS_ENGLISH_LANGUAGE
  end
  if name_record.platform_id == MACINTOSH_PLATFORM then
    return name_record.language_id == MACINTOSH_ENGLISH_LANGUAGE
  end
  return true
end

---@param records NameRecordProps[]
---@param name_id integer
---@return string?
local function find_english_value(records, name_id)
  ---@type string?
  local fallback_value = nil
  for _, name_record in ipairs(records) do
    if name_record.name_id == name_id and name_record.value ~= '' then
      if is_english(name_record) then return name_record.value end
      fallback_value = fallback_value or name_record.value
    end
  end
  return fallback_value
end

---@param records NameRecordProps[]
---@return string[]
local function collect_family_names(records)
  ---@type string[]
  local family_names = {}
  ---@type table<string, boolean>
  local seen_names = {}
  for _, name_record in ipairs(records) do
    if
      (
        name_record.name_id == FAMILY_NAME_ID
        or name_record.name_id == TYPOGRAPHIC_FAMILY_NAME_ID
      )
      and name_record.value ~= ''
      and not seen_names[name_record.value]
    then
      seen_names[name_record.value] = true
      family_names[#family_names + 1] = name_record.value
    end
  end
  return family_names
end

---@param data string
---@param offset integer
---@return FontNamesProps
function font_name_reader.read(data, offset)
  local records = read_records(data, offset)
  return {
    family_names = collect_family_names(records),
    style_name = find_english_value(records, TYPOGRAPHIC_STYLE_NAME_ID)
      or find_english_value(records, STYLE_NAME_ID)
      or '',
  }
end

return font_name_reader
