local compact_font_structure_reader =
  require 'scaled_markdown.core.font.compact_font_structure_reader'
local font_binary_reader =
  require 'scaled_markdown.core.font.font_binary_reader'
local type2_charstring_interpreter =
  require 'scaled_markdown.core.font.type2_charstring_interpreter'

local HEADER_SIZE_OFFSET = 2
local CHARSTRINGS_OPERATOR = 17
local PRIVATE_OPERATOR = 18
local SUBROUTINES_OPERATOR = 19
local CHARSTRING_TYPE_OPERATOR = 1206
local FONT_DICT_ARRAY_OPERATOR = 1236
local FONT_DICT_SELECT_OPERATOR = 1237
local SUPPORTED_CHARSTRING_TYPE = 2
local ARRAY_SELECT_FORMAT = 0
local RANGE_SELECT_FORMAT = 3
local RANGE_RECORD_LENGTH = 3

---@alias FontDictSelectorProps fun(glyph_index: integer): integer

---@class compact_font_outline_reader
local compact_font_outline_reader = {}

---@param data string
---@param index CompactFontIndexProps
---@param item_index integer
---@return CompactFontDictProps
local function read_index_item_dict(data, index, item_index)
  local start_offset, end_offset =
    compact_font_structure_reader.item_range(data, index, item_index)
  if not start_offset or not end_offset then return {} end
  return compact_font_structure_reader.read_dict(data, start_offset, end_offset)
end

---@param data string
---@param table_offset integer
---@param font_dict CompactFontDictProps
---@return CompactFontIndexProps?
local function read_local_subroutines(data, table_offset, font_dict)
  local private_entry = font_dict[PRIVATE_OPERATOR]
  if not private_entry or #private_entry < 2 then return nil end
  local private_size = math.floor(private_entry[1])
  local private_offset = table_offset + math.floor(private_entry[2])
  local private_dict = compact_font_structure_reader.read_dict(
    data,
    private_offset,
    private_offset + private_size
  )
  local subroutines_entry = private_dict[SUBROUTINES_OPERATOR]
  if not subroutines_entry or #subroutines_entry < 1 then return nil end
  return compact_font_structure_reader.read_index(
    data,
    private_offset + math.floor(subroutines_entry[1])
  )
end

---@param data string
---@param select_offset integer
---@return FontDictSelectorProps
local function build_range_selector(data, select_offset)
  local range_count = font_binary_reader.read_uint16(data, select_offset + 1)
  local ranges_offset = select_offset + 3
  return function(glyph_index)
    for range_index = 0, range_count - 1 do
      local range_offset = ranges_offset + range_index * RANGE_RECORD_LENGTH
      local next_first_glyph =
        font_binary_reader.read_uint16(data, range_offset + RANGE_RECORD_LENGTH)
      if glyph_index < next_first_glyph then
        return font_binary_reader.read_uint8(data, range_offset + 2)
      end
    end
    return 0
  end
end

---@param data string
---@param select_offset integer
---@return FontDictSelectorProps
local function build_font_dict_selector(data, select_offset)
  local format = font_binary_reader.read_uint8(data, select_offset)
  if format == ARRAY_SELECT_FORMAT then
    return function(glyph_index)
      return font_binary_reader.read_uint8(
        data,
        select_offset + 1 + glyph_index
      )
    end
  end
  if format == RANGE_SELECT_FORMAT then
    return build_range_selector(data, select_offset)
  end
  return function(_) return 0 end
end

---@param data string
---@param table_offset integer
---@param top_dict CompactFontDictProps
---@return fun(glyph_index: integer): CompactFontIndexProps?
local function resolve_local_subroutine_lookup(data, table_offset, top_dict)
  local font_dict_array_entry = top_dict[FONT_DICT_ARRAY_OPERATOR]
  local font_dict_select_entry = top_dict[FONT_DICT_SELECT_OPERATOR]
  if not font_dict_array_entry or not font_dict_select_entry then
    local local_subroutines =
      read_local_subroutines(data, table_offset, top_dict)
    return function(_) return local_subroutines end
  end
  local font_dict_array = compact_font_structure_reader.read_index(
    data,
    table_offset + math.floor(font_dict_array_entry[1])
  )
  local select_font_dict = build_font_dict_selector(
    data,
    table_offset + math.floor(font_dict_select_entry[1])
  )
  ---@type table<integer, CompactFontIndexProps|boolean>
  local subroutines_by_font_dict = {}
  return function(glyph_index)
    local font_dict_index = select_font_dict(glyph_index)
    if subroutines_by_font_dict[font_dict_index] == nil then
      subroutines_by_font_dict[font_dict_index] = read_local_subroutines(
        data,
        table_offset,
        read_index_item_dict(data, font_dict_array, font_dict_index)
      ) or false
    end
    local subroutines = subroutines_by_font_dict[font_dict_index]
    return type(subroutines) == 'table' and subroutines or nil
  end
end

---@param data string
---@param table_offset integer
---@return GlyphOutlineLoaderProps?
function compact_font_outline_reader.create_loader(data, table_offset)
  local header_size =
    font_binary_reader.read_uint8(data, table_offset + HEADER_SIZE_OFFSET)
  local name_index =
    compact_font_structure_reader.read_index(data, table_offset + header_size)
  local top_dict_index =
    compact_font_structure_reader.read_index(data, name_index.end_offset)
  local string_index =
    compact_font_structure_reader.read_index(data, top_dict_index.end_offset)
  local global_subroutines =
    compact_font_structure_reader.read_index(data, string_index.end_offset)
  local top_dict = read_index_item_dict(data, top_dict_index, 0)
  local charstring_type = top_dict[CHARSTRING_TYPE_OPERATOR]
  if charstring_type and charstring_type[1] ~= SUPPORTED_CHARSTRING_TYPE then
    return nil
  end
  local charstrings_entry = top_dict[CHARSTRINGS_OPERATOR]
  if not charstrings_entry or #charstrings_entry < 1 then return nil end
  local charstrings = compact_font_structure_reader.read_index(
    data,
    table_offset + math.floor(charstrings_entry[1])
  )
  local find_local_subroutines =
    resolve_local_subroutine_lookup(data, table_offset, top_dict)
  return function(glyph_index)
    local start_offset, end_offset =
      compact_font_structure_reader.item_range(data, charstrings, glyph_index)
    if not start_offset or not end_offset then return nil end
    return type2_charstring_interpreter.interpret(
      data,
      start_offset,
      end_offset,
      global_subroutines,
      find_local_subroutines(glyph_index)
    )
  end
end

return compact_font_outline_reader
