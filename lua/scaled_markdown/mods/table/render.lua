









local CORE_CONSTANTS = require('scaled_markdown.core.constants')
local ALIGNMENT_ENUM = require('scaled_markdown.mods.table.alignment_enum')

local TABLE_ROW_KIND_ENUM =
require('scaled_markdown.mods.table.table_row_kind_enum')
local border_line_builder =
require('scaled_markdown.core.border.border_line_builder')
local gradient_chunks = require('scaled_markdown.core.highlight.gradient_chunks')
local table_dto_builder = require('scaled_markdown.mods.table.table_dto_builder')
local table_highlight = require('scaled_markdown.mods.table.highlight')
local utf8_text = require('scaled_markdown.core.text.utf8_text')



local PAD_FUNCTION_BY_ALIGNMENT = {
   [ALIGNMENT_ENUM.LEFT] = utf8_text.pad_right,
   [ALIGNMENT_ENUM.CENTER] = utf8_text.pad_center,
   [ALIGNMENT_ENUM.RIGHT] = utf8_text.pad_left,
}



local table_render = {}


local function build_padded_widths(
   table_dto,
   cell_padding)

   local padded_widths = {}
   for column_index, column_width in ipairs(table_dto.column_widths) do
      padded_widths[column_index] = column_width + cell_padding * 2
   end
   return padded_widths
end

local function build_cell_row_segments(
   row_dto,
   table_dto,
   cell_padding)

   local vertical = border_line_builder.vertical()
   local padding = string.rep(' ', cell_padding)
   local cell_highlight = row_dto.kind == TABLE_ROW_KIND_ENUM.HEADER and
   table_highlight.GROUPS.HEADER_CELL or
   table_highlight.GROUPS.BODY_CELL
   local segments = { { text = vertical } }
   for column_index, column_width in ipairs(table_dto.column_widths) do
      local alignment = table_dto.alignments[column_index] or ALIGNMENT_ENUM.LEFT
      local aligned_text = PAD_FUNCTION_BY_ALIGNMENT[alignment](
      row_dto.cells[column_index] or '',
      column_width)

      segments[#segments + 1] =
      { text = padding .. aligned_text .. padding, highlight = cell_highlight }
      segments[#segments + 1] = { text = vertical }
   end
   return segments
end

local function build_row_chunks(
   row_dto,
   table_dto,
   padded_widths,
   context_dto)

   if row_dto.kind == TABLE_ROW_KIND_ENUM.DELIMITER then
      return gradient_chunks.from_text(
      border_line_builder.build_grid_separator(padded_widths))

   end
   return gradient_chunks.from_segments(
   build_cell_row_segments(
   row_dto,
   table_dto,
   context_dto.mod_config.cell_padding))


end

local function measure_chunks(chunks)
   local width = 0
   for _, chunk in ipairs(chunks) do
      width = width + utf8_text.display_width(chunk[1])
   end
   return width
end

local function overlay_row(
   row_dto,
   chunks,
   table_dto,
   context_dto)

   local source_width = utf8_text.display_width(context_dto.line_at(row_dto.row)) -
   table_dto.left_col
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

local function build_virtual_border_line(
   border_text,
   table_dto)

   local chunks = gradient_chunks.from_text(border_text)
   table.insert(
   chunks,
   1,
   { string.rep(' ', table_dto.left_col), CORE_CONSTANTS.PADDING_HIGHLIGHT })

   return chunks
end

local function attach_outer_borders(
   table_dto,
   padded_widths,
   context_dto)

   local first_row_dto, last_row_dto =
   table_dto.rows[1], table_dto.rows[#table_dto.rows]
   context_dto.writer.set_extmark(first_row_dto.row, 0, {
      virt_lines = {
         build_virtual_border_line(
         border_line_builder.build_grid_top(padded_widths),
         table_dto),

      },
      virt_lines_above = true,
   })
   context_dto.writer.set_extmark(last_row_dto.row, 0, {
      virt_lines = {
         build_virtual_border_line(
         border_line_builder.build_grid_bottom(padded_widths),
         table_dto),

      },
   })
end

function table_render.render(
   capture_dto,
   mod_context_dto)

   local context_dto = mod_context_dto
   local mod_config = context_dto.mod_config
   local table_dto = table_dto_builder.build(
   capture_dto,
   context_dto.buf,
   mod_config.min_column_width)

   if #table_dto.rows == 0 or #table_dto.column_widths == 0 then return end
   local padded_widths = build_padded_widths(table_dto, mod_config.cell_padding)
   for _, row_dto in ipairs(table_dto.rows) do
      overlay_row(
      row_dto,
      build_row_chunks(row_dto, table_dto, padded_widths, context_dto),
      table_dto,
      context_dto)

   end
   attach_outer_borders(table_dto, padded_widths, context_dto)
end

return table_render
