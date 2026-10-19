local font_binary_reader =
  require 'scaled_markdown.core.font.font_binary_reader'

local METRIC_COUNT_OFFSET = 34
local METRIC_RECORD_LENGTH = 4
local MISSING_ADVANCE_WIDTH = 0

---@alias AdvanceWidthLookupProps fun(glyph_index: integer): number

---@class font_advance_widths
local font_advance_widths = {}

---@param data string
---@param tables table<string, FontTableProps>
---@return AdvanceWidthLookupProps
function font_advance_widths.create_lookup(data, tables)
  if not tables.hhea or not tables.hmtx then
    return function(_) return MISSING_ADVANCE_WIDTH end
  end
  local metric_count = font_binary_reader.read_uint16(
    data,
    tables.hhea.offset + METRIC_COUNT_OFFSET
  )
  local metrics_offset = tables.hmtx.offset
  return function(glyph_index)
    if metric_count == 0 then return MISSING_ADVANCE_WIDTH end
    local metric_index = math.min(glyph_index, metric_count - 1)
    return font_binary_reader.read_uint16(
      data,
      metrics_offset + metric_index * METRIC_RECORD_LENGTH
    )
  end
end

return font_advance_widths
