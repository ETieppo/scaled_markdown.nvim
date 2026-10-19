local ALIGNMENT_ENUM = require 'scaled_markdown.mods.table.alignment_enum'
local type AlignmentEnum = ALIGNMENT_ENUM.AlignmentEnum
local TABLE_ROW_KIND_ENUM =
  require 'scaled_markdown.mods.table.table_row_kind_enum'
local type TableRowKindEnum = TABLE_ROW_KIND_ENUM.TableRowKindEnum

local record TableRowProps
  row: integer
  kind: TableRowKindEnum
  cells: {string}
  alignments: {AlignmentEnum}
end

return TableRowProps
