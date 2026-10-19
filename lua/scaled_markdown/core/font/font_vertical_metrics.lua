local font_binary_reader =
  require 'scaled_markdown.core.font.font_binary_reader'

local HORIZONTAL_ASCENDER_OFFSET = 4
local HORIZONTAL_DESCENDER_OFFSET = 6
local HORIZONTAL_LINE_GAP_OFFSET = 8
local TYPOGRAPHIC_ASCENDER_OFFSET = 68
local TYPOGRAPHIC_DESCENDER_OFFSET = 70
local TYPOGRAPHIC_LINE_GAP_OFFSET = 72

---@class VerticalMetricsProps
---@field ascender number
---@field descender number
---@field line_gap number

---@class font_vertical_metrics
local font_vertical_metrics = {}

---@param data string
---@param offset integer
---@param ascender_offset integer
---@param descender_offset integer
---@param line_gap_offset integer
---@return VerticalMetricsProps
local function read_metrics(
  data,
  offset,
  ascender_offset,
  descender_offset,
  line_gap_offset
)
  return {
    ascender = font_binary_reader.read_int16(data, offset + ascender_offset),
    descender = font_binary_reader.read_int16(data, offset + descender_offset),
    line_gap = font_binary_reader.read_int16(data, offset + line_gap_offset),
  }
end

---@param data string
---@param tables table<string, FontTableProps>
---@param units_per_em number
---@return VerticalMetricsProps
function font_vertical_metrics.read(data, tables, units_per_em)
  if tables.hhea then
    local metrics = read_metrics(
      data,
      tables.hhea.offset,
      HORIZONTAL_ASCENDER_OFFSET,
      HORIZONTAL_DESCENDER_OFFSET,
      HORIZONTAL_LINE_GAP_OFFSET
    )
    if metrics.ascender ~= 0 or metrics.descender ~= 0 then return metrics end
  end
  if tables['OS/2'] then
    return read_metrics(
      data,
      tables['OS/2'].offset,
      TYPOGRAPHIC_ASCENDER_OFFSET,
      TYPOGRAPHIC_DESCENDER_OFFSET,
      TYPOGRAPHIC_LINE_GAP_OFFSET
    )
  end
  return { ascender = units_per_em, descender = 0, line_gap = 0 }
end

return font_vertical_metrics
