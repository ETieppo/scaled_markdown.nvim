local ALIGNMENT_ENUM = require 'scaled_markdown.mods.table.alignment_enum'
local TABLE_ROW_KIND_ENUM =
  require 'scaled_markdown.mods.table.table_row_kind_enum'
local table_cell_parser = require 'scaled_markdown.mods.table.table_cell_parser'
local utf8_text = require 'scaled_markdown.core.text.utf8_text'

---@type table<string, TableRowKindEnum>
local ROW_KIND_BY_NODE_TYPE = {
  pipe_table_header = TABLE_ROW_KIND_ENUM.HEADER,
  pipe_table_delimiter_row = TABLE_ROW_KIND_ENUM.DELIMITER,
  pipe_table_row = TABLE_ROW_KIND_ENUM.BODY,
}
local CELL_NODE_TYPE = 'pipe_table_cell'
local DELIMITER_CELL_NODE_TYPE = 'pipe_table_delimiter_cell'
local ALIGN_LEFT_NODE_TYPE = 'pipe_table_align_left'
local ALIGN_RIGHT_NODE_TYPE = 'pipe_table_align_right'

---@class table_dto_builder
local table_dto_builder = {}

---@param delimiter_cell_node TSNode
---@return AlignmentEnum
local function resolve_alignment(delimiter_cell_node)
  local has_left, has_right = false, false
  for child in delimiter_cell_node:iter_children() do
    has_left = has_left or child:type() == ALIGN_LEFT_NODE_TYPE
    has_right = has_right or child:type() == ALIGN_RIGHT_NODE_TYPE
  end
  if has_left and has_right then return ALIGNMENT_ENUM.CENTER end
  return has_right and ALIGNMENT_ENUM.RIGHT or ALIGNMENT_ENUM.LEFT
end

---@param row_node TSNode
---@param row_kind TableRowKindEnum
---@param buf integer
---@return TableRowProps
local function collect_row(row_node, row_kind, buf)
  ---@type TableRowProps
  local row_dto =
    { row = (row_node:range()), kind = row_kind, cells = {}, alignments = {} }
  for child in row_node:iter_children() do
    if child:type() == CELL_NODE_TYPE then
      row_dto.cells[#row_dto.cells + 1] = table_cell_parser.parse(
        utf8_text.trim(vim.treesitter.get_node_text(child, buf))
      )
    elseif child:type() == DELIMITER_CELL_NODE_TYPE then
      row_dto.alignments[#row_dto.alignments + 1] = resolve_alignment(child)
    end
  end
  return row_dto
end

---@param row_dtos TableRowProps[]
---@param column_count integer
---@param min_column_width integer
---@return integer[]
local function compute_column_widths(row_dtos, column_count, min_column_width)
  ---@type integer[]
  local column_widths = {}
  for column_index = 1, column_count do
    column_widths[column_index] = min_column_width
    for _, row_dto in ipairs(row_dtos) do
      local cell_dto = row_dto.cells[column_index]
      column_widths[column_index] = math.max(
        column_widths[column_index],
        cell_dto and utf8_text.display_width(cell_dto.text) or 0
      )
    end
  end
  return column_widths
end

---@param capture_dto CaptureProps
---@param buf integer
---@param min_column_width integer
---@return TableProps
function table_dto_builder.build(capture_dto, buf, min_column_width)
  ---@type TableRowProps[]
  local row_dtos = {}
  ---@type AlignmentEnum[]
  local alignments = {}
  local column_count = 0
  for child in capture_dto.node:iter_children() do
    local row_kind = ROW_KIND_BY_NODE_TYPE[child:type()]
    if row_kind then
      local row_dto = collect_row(child, row_kind, buf)
      row_dtos[#row_dtos + 1] = row_dto
      if row_kind == TABLE_ROW_KIND_ENUM.DELIMITER then
        alignments = row_dto.alignments
      end
      column_count = math.max(column_count, #row_dto.cells, #row_dto.alignments)
    end
  end
  return {
    left_col = capture_dto.start_col,
    rows = row_dtos,
    alignments = alignments,
    column_widths = compute_column_widths(
      row_dtos,
      column_count,
      min_column_width
    ),
  }
end

return table_dto_builder
