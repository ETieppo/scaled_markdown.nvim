

local CORE_CONSTANTS = require('scaled_markdown.core.constants')

local BLANK_VIRTUAL_LINE = {}

local extmark_writer = {}


local function build_height_placeholder(
   extmark_options)

   if not extmark_options.virt_lines or #extmark_options.virt_lines == 0 then
      return nil
   end
   local blank_lines = {}
   for line_index = 1, #extmark_options.virt_lines do
      blank_lines[line_index] = BLANK_VIRTUAL_LINE
   end
   return {
      virt_lines = blank_lines,
      virt_lines_above = extmark_options.virt_lines_above,
   }
end

local function anchor_virtual_lines_to_left_column(
   extmark_options,
   text_offset)

   if not extmark_options.virt_lines then return extmark_options end
   local gutter_chunk =
   { string.rep(' ', text_offset), CORE_CONSTANTS.PADDING_HIGHLIGHT }
   local anchored_lines = {}
   for line_index, line_chunks in ipairs(extmark_options.virt_lines) do
      anchored_lines[line_index] = { gutter_chunk, unpack(line_chunks) }
   end
   return vim.tbl_extend('force', extmark_options, {
      virt_lines = anchored_lines,
      virt_lines_leftcol = true,
   })
end

function extmark_writer.new(
   buf,
   namespace_id,
   revealed_rows,
   text_offset)

   local writer = {}

   function writer.set_extmark(
      row,
      col,
      extmark_options)

      if revealed_rows[row] then
         extmark_options = build_height_placeholder(extmark_options)
         if not extmark_options then return nil end
      end
      local options = vim.tbl_extend(
      'force',
      { strict = false },
      anchor_virtual_lines_to_left_column(extmark_options, text_offset))

      local ok, extmark_id =
      pcall(vim.api.nvim_buf_set_extmark, buf, namespace_id, row, col, options)
      return ok and extmark_id or nil
   end

   return writer
end

return extmark_writer
