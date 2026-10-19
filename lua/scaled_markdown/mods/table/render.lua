local CORE_CONSTANTS = require 'scaled_markdown.core.constants'
local ALIGNMENT_ENUM = require 'scaled_markdown.mods.table.alignment_enum'
local TABLE_ROW_KIND_ENUM =
  require 'scaled_markdown.mods.table.table_row_kind_enum'
local border_line_builder =
  require 'scaled_markdown.core.border.border_line_builder'
local gradient_chunks = require 'scaled_markdown.core.highlight.gradient_chunks'
local table_dto_builder = require 'scaled_markdown.mods.table.table_dto_builder'
local table_highlight = require 'scaled_markdown.mods.table.highlight'
local utf8_text = require 'scaled_markdown.core.text.utf8_text'

---@alias LeadingWidthFunctionProps fun(free_width: integer): integer

---@type table<AlignmentEnum, LeadingWidthFunctionProps>
local LEADING_WIDTH_FUNCTION_BY_ALIGNMENT = {
  [ALIGNMENT_ENUM.LEFT] = function() return 0 end,
  [ALIGNMENT_ENUM.CENTER] = function(free_width)
    return math.floor(free_width / 2)
  end,
  [ALIGNMENT_ENUM.RIGHT] = function(free_width) return free_width end,
}
---@type TableCellProps
local EMPTY_CELL = { text = '', segments = {} }

---@alias TableContextProps RenderContextProps<TableConfigProps>

---@class table_render
local table_render = {}

---@param table_dto TableProps
---@param cell_padding integer
---@return integer[]
local function build_padded_widths(table_dto, cell_padding)
  ---@type integer[]
  local padded_widths = {}
  for column_index, column_width in ipairs(table_dto.column_widths) do
    padded_widths[column_index] = column_width + cell_padding * 2
  end
  return padded_widths
end

---@param segments GradientSegmentProps[]
---@param cell_dto TableCellProps
---@param leading_width integer
---@param trailing_width integer
---@param cell_highlight string
local function append_cell_segments(
  segments,
  cell_dto,
  leading_width,
  trailing_width,
  cell_highlight
)
  segments[#segments + 1] =
    { text = string.rep(' ', leading_width), highlight = cell_highlight }
  for _, cell_segment in ipairs(cell_dto.segments) do
    segments[#segments + 1] = {
      text = cell_segment.text,
      highlight = cell_segment.is_code and table_highlight.GROUPS.INLINE_CODE
        or cell_highlight,
    }
  end
  segments[#segments + 1] =
    { text = string.rep(' ', trailing_width), highlight = cell_highlight }
end

---@param row_dto TableRowProps
---@param table_dto TableProps
---@param cell_padding integer
---@return GradientSegmentProps[]
local function build_cell_row_segments(row_dto, table_dto, cell_padding)
  local vertical = border_line_builder.vertical()
  local cell_highlight = row_dto.kind == TABLE_ROW_KIND_ENUM.HEADER
      and table_highlight.GROUPS.HEADER_CELL
    or table_highlight.GROUPS.BODY_CELL
  ---@type GradientSegmentProps[]
  local segments = { { text = vertical } }
  for column_index, column_width in ipairs(table_dto.column_widths) do
    local alignment = table_dto.alignments[column_index] or ALIGNMENT_ENUM.LEFT
    local cell_dto = row_dto.cells[column_index] or EMPTY_CELL
    local free_width =
      math.max(0, column_width - utf8_text.display_width(cell_dto.text))
    local leading_width =
      LEADING_WIDTH_FUNCTION_BY_ALIGNMENT[alignment](free_width)
    append_cell_segments(
      segments,
      cell_dto,
      cell_padding + leading_width,
      cell_padding + free_width - leading_width,
      cell_highlight
    )
    segments[#segments + 1] = { text = vertical }
  end
  return segments
end

---@param row_dto TableRowProps
---@param table_dto TableProps
---@param padded_widths integer[]
---@param context_dto TableContextProps
---@return [string, string][]
local function build_row_chunks(row_dto, table_dto, padded_widths, context_dto)
  if row_dto.kind == TABLE_ROW_KIND_ENUM.DELIMITER then
    return gradient_chunks.from_text(
      border_line_builder.build_grid_separator(padded_widths)
    )
  end
  return gradient_chunks.from_segments(
    build_cell_row_segments(
      row_dto,
      table_dto,
      context_dto.mod_config.cell_padding
    )
  )
end

---@param chunks [string, string][]
---@return integer
local function measure_chunks(chunks)
  local width = 0
  for _, chunk in ipairs(chunks) do
    width = width + utf8_text.display_width(chunk[1])
  end
  return width
end

---@param row_dto TableRowProps
---@param chunks [string, string][]
---@param table_dto TableProps
---@param context_dto TableContextProps
local function overlay_row(row_dto, chunks, table_dto, context_dto)
  local source_width = utf8_text.display_width(context_dto.line_at(row_dto.row))
    - table_dto.left_col
  local uncovered_width = source_width - measure_chunks(chunks)
  if uncovered_width > 0 then
    chunks[#chunks + 1] =
      { string.rep(' ', uncovered_width), CORE_CONSTANTS.PADDING_HIGHLIGHT }
  end
  context_dto.writer.set_extmark(row_dto.row, table_dto.left_col, {
    virt_text = chunks,
    virt_text_pos = 'overlay',
  })
end

---@param border_text string
---@param table_dto TableProps
---@return [string, string][]
local function build_virtual_border_line(border_text, table_dto)
  local chunks = gradient_chunks.from_text(border_text)
  table.insert(
    chunks,
    1,
    { string.rep(' ', table_dto.left_col), CORE_CONSTANTS.PADDING_HIGHLIGHT }
  )
  return chunks
end

---@param table_dto TableProps
---@param padded_widths integer[]
---@param context_dto TableContextProps
local function attach_outer_borders(table_dto, padded_widths, context_dto)
  local first_row_dto, last_row_dto =
    table_dto.rows[1], table_dto.rows[#table_dto.rows]
  context_dto.writer.set_extmark(first_row_dto.row, 0, {
    virt_lines = {
      build_virtual_border_line(
        border_line_builder.build_grid_top(padded_widths),
        table_dto
      ),
    },
    virt_lines_above = true,
  })
  context_dto.writer.set_extmark(last_row_dto.row, 0, {
    virt_lines = {
      build_virtual_border_line(
        border_line_builder.build_grid_bottom(padded_widths),
        table_dto
      ),
    },
  })
end

---@param capture_dto CaptureProps
---@param mod_context_dto RenderContextProps<ModConfigProps>
function table_render.render(capture_dto, mod_context_dto)
  ---@type TableContextProps
  local context_dto = mod_context_dto
  local mod_config = context_dto.mod_config
  local table_dto = table_dto_builder.build(
    capture_dto,
    context_dto.buf,
    mod_config.min_column_width
  )
  if #table_dto.rows == 0 or #table_dto.column_widths == 0 then return end
  local padded_widths = build_padded_widths(table_dto, mod_config.cell_padding)
  for _, row_dto in ipairs(table_dto.rows) do
    overlay_row(
      row_dto,
      build_row_chunks(row_dto, table_dto, padded_widths, context_dto),
      table_dto,
      context_dto
    )
  end
  attach_outer_borders(table_dto, padded_widths, context_dto)
end

return table_render
