local type TableRowProps = require 'scaled_markdown.mods.table.table_row_props'
local ALIGNMENT_ENUM = require 'scaled_markdown.mods.table.alignment_enum'
local type AlignmentEnum = ALIGNMENT_ENUM.AlignmentEnum

local record TableProps
  left_col: integer
  rows: {TableRowProps}
  alignments: {AlignmentEnum}
  column_widths: {integer}
end

return TableProps
