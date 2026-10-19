local compact_font_outline_reader =
  require 'scaled_markdown.core.font.compact_font_outline_reader'
local font_advance_widths =
  require 'scaled_markdown.core.font.font_advance_widths'
local font_binary_reader =
  require 'scaled_markdown.core.font.font_binary_reader'
local font_character_map =
  require 'scaled_markdown.core.font.font_character_map'
local font_kerning_table =
  require 'scaled_markdown.core.font.font_kerning_table'
local font_vertical_metrics =
  require 'scaled_markdown.core.font.font_vertical_metrics'
local sfnt_table_directory =
  require 'scaled_markdown.core.font.sfnt_table_directory'
local true_type_outline_reader =
  require 'scaled_markdown.core.font.true_type_outline_reader'

local READ_BINARY_MODE = 'rb'
local READ_ALL_FORMAT = '*a'
local UNITS_PER_EM_OFFSET = 18
local LOCATION_FORMAT_OFFSET = 50
local GLYPH_COUNT_OFFSET = 4
local COMPACT_FONT_TABLE_TAG = 'CFF '
local KEY_SEPARATOR = '\31'
local UNLOADED_FACE_MARKER = false
---@type GlyphOutlineProps
local EMPTY_OUTLINE = { commands = {} }

---@class font_face_loader
local font_face_loader = {}

---@type table<string, FontFaceProps|boolean>
local face_by_key = {}

---@param path string
---@return string?
local function read_file(path)
  local file = io.open(path, READ_BINARY_MODE)
  if not file then return nil end
  ---@type string
  local data = file:read(READ_ALL_FORMAT)
  file:close()
  return data
end

---@param data string
---@param tables table<string, FontTableProps>
---@return GlyphOutlineLoaderProps?
local function create_outline_loader(data, tables)
  if tables.glyf and tables.loca and tables.head and tables.maxp then
    return true_type_outline_reader.create_loader(
      data,
      tables,
      font_binary_reader.read_uint16(
        data,
        tables.maxp.offset + GLYPH_COUNT_OFFSET
      ),
      font_binary_reader.read_int16(
        data,
        tables.head.offset + LOCATION_FORMAT_OFFSET
      )
    )
  end
  local compact_font_table = tables[COMPACT_FONT_TABLE_TAG]
  if compact_font_table then
    return compact_font_outline_reader.create_loader(
      data,
      compact_font_table.offset
    )
  end
  return nil
end

---@param load_outline GlyphOutlineLoaderProps
---@return fun(glyph_index: integer): GlyphOutlineProps
local function cache_outlines(load_outline)
  ---@type table<integer, GlyphOutlineProps>
  local outline_by_glyph_index = {}
  return function(glyph_index)
    local cached_outline = outline_by_glyph_index[glyph_index]
    if cached_outline then return cached_outline end
    local ok, outline = pcall(load_outline, glyph_index)
    local resolved_outline = ok and outline or EMPTY_OUTLINE
    outline_by_glyph_index[glyph_index] = resolved_outline
    return resolved_outline
  end
end

---@param data string
---@param face_index integer
---@return FontFaceProps?
local function build_face(data, face_index)
  local tables = sfnt_table_directory.read(
    ---@param offset integer
    ---@param length integer
    ---@return string
    function(offset, length) return data:sub(offset + 1, offset + length) end,
    face_index
  )
  if not tables or not tables.head or not tables.cmap then return nil end
  local load_outline = create_outline_loader(data, tables)
  if not load_outline then return nil end
  local units_per_em = font_binary_reader.read_uint16(
    data,
    tables.head.offset + UNITS_PER_EM_OFFSET
  )
  local metrics = font_vertical_metrics.read(data, tables, units_per_em)
  return {
    units_per_em = units_per_em,
    ascender = metrics.ascender,
    descender = metrics.descender,
    line_gap = metrics.line_gap,
    find_glyph_index = font_character_map.create_lookup(
      data,
      tables.cmap.offset
    ),
    advance_width = font_advance_widths.create_lookup(data, tables),
    kerning = font_kerning_table.create_lookup(data, tables.kern),
    load_outline = cache_outlines(load_outline),
  }
end

---@param font_file FontFileProps
---@return FontFaceProps?
local function load_face(font_file)
  local data = read_file(font_file.path)
  if not data then return nil end
  local ok, face = pcall(build_face, data, font_file.face_index)
  return ok and face or nil
end

---@param font_file FontFileProps
---@return FontFaceProps?
function font_face_loader.load(font_file)
  local key = font_file.path .. KEY_SEPARATOR .. font_file.face_index
  if face_by_key[key] == nil then
    face_by_key[key] = load_face(font_file) or UNLOADED_FACE_MARKER
  end
  local face = face_by_key[key]
  return type(face) == 'table' and face or nil
end

return font_face_loader
