local type CaptureProps = require 'scaled_markdown.core.types.capture_props'
local type TableProps = require 'scaled_markdown.mods.table.table_props'
local type TableRowProps = require 'scaled_markdown.mods.table.table_row_props'
local ALIGNMENT_ENUM = require 'scaled_markdown.mods.table.alignment_enum'
local type AlignmentEnum = ALIGNMENT_ENUM.AlignmentEnum
local TABLE_ROW_KIND_ENUM =
  require 'scaled_markdown.mods.table.table_row_kind_enum'
local type TableRowKindEnum = TABLE_ROW_KIND_ENUM.TableRowKindEnum
local utf8_text = require 'scaled_markdown.core.text.utf8_text'

local ROW_KIND_BY_NODE_TYPE <const>: {string: TableRowKindEnum} = {
  pipe_table_header = TABLE_ROW_KIND_ENUM.HEADER,
  pipe_table_delimiter_row = TABLE_ROW_KIND_ENUM.DELIMITER,
  pipe_table_row = TABLE_ROW_KIND_ENUM.BODY,
}
local CELL_NODE_TYPE <const> = 'pipe_table_cell'
local DELIMITER_CELL_NODE_TYPE <const> = 'pipe_table_delimiter_cell'
local ALIGN_LEFT_NODE_TYPE <const> = 'pipe_table_align_left'
local ALIGN_RIGHT_NODE_TYPE <const> = 'pipe_table_align_right'

local record table_dto_builder
end

local function resolve_alignment(
  delimiter_cell_node: vim.TSNodeProps
): AlignmentEnum
  local has_left, has_right = false, false
  for child in delimiter_cell_node:iter_children() do
    has_left = has_left or child:type() == ALIGN_LEFT_NODE_TYPE
    has_right = has_right or child:type() == ALIGN_RIGHT_NODE_TYPE
  end
  if has_left and has_right then return ALIGNMENT_ENUM.CENTER end
  return has_right and ALIGNMENT_ENUM.RIGHT or ALIGNMENT_ENUM.LEFT
end

local function collect_row(
  row_node: vim.TSNodeProps,
  row_kind: TableRowKindEnum,
  buf: integer
): TableRowProps
  local row_dto: TableRowProps =
    { row = (row_node:range()), kind = row_kind, cells = {}, alignments = {} }
  for child in row_node:iter_children() do
    if child:type() == CELL_NODE_TYPE then
      row_dto.cells[#row_dto.cells + 1] =
        utf8_text.trim(vim.treesitter.get_node_text(child, buf))
    elseif child:type() == DELIMITER_CELL_NODE_TYPE then
      row_dto.alignments[#row_dto.alignments + 1] = resolve_alignment(child)
    end
  end
  return row_dto
end

local function compute_column_widths(
  row_dtos: {TableRowProps},
  column_count: integer,
  min_column_width: integer
): {integer}
  local column_widths: {integer} = {}
  for column_index = 1, column_count do
    column_widths[column_index] = min_column_width
    for _, row_dto in ipairs(row_dtos) do
      local cell_text = row_dto.cells[column_index] or ''
      column_widths[column_index] = math.max(
        column_widths[column_index],
        utf8_text.display_width(cell_text)
      )
    end
  end
  return column_widths
end

function table_dto_builder.build(
  capture_dto: CaptureProps,
  buf: integer,
  min_column_width: integer
): TableProps
  local row_dtos: {TableRowProps} = {}
  local alignments: {AlignmentEnum} = {}
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
