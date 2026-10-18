



local DELIMITER_NODE_TYPE = 'fenced_code_block_delimiter'
local INFO_STRING_NODE_TYPE = 'info_string'
local LANGUAGE_NODE_TYPE = 'language'

local code_block_dto_builder = {}


local function find_language(
   info_string_node,
   buf)

   for child in info_string_node:iter_children() do
      if child:type() == LANGUAGE_NODE_TYPE then
         return vim.treesitter.get_node_text(child, buf)
      end
   end
   return vim.trim(vim.treesitter.get_node_text(info_string_node, buf))
end

local function skip_trailing_blank_rows(
   buf,
   first_row,
   last_row)

   while last_row > first_row do
      local line = vim.api.nvim_buf_get_lines(buf, last_row, last_row + 1, false)[1] or
      ''
      if vim.trim(line) ~= '' then break end
      last_row = last_row - 1
   end
   return last_row
end

function code_block_dto_builder.build(
   capture_dto,
   buf)

   local delimiter_rows = {}
   local language = nil

   for child in capture_dto.node:iter_children() do
      if child:type() == DELIMITER_NODE_TYPE then
         delimiter_rows[#delimiter_rows + 1] = (child:range())
      elseif child:type() == INFO_STRING_NODE_TYPE then
         language = find_language(child, buf)
      end
   end

   local opening_fence_row, closing_fence_row =
   delimiter_rows[1], delimiter_rows[2]
   local first_content_row = opening_fence_row and opening_fence_row + 1 or
   capture_dto.start_row
   local node_last_row = capture_dto.end_col == 0 and capture_dto.end_row - 1 or
   capture_dto.end_row

   return {
      language = language,
      left_col = capture_dto.start_col,
      opening_fence_row = opening_fence_row,
      closing_fence_row = closing_fence_row,
      first_content_row = first_content_row,
      last_content_row = closing_fence_row and closing_fence_row - 1 or
      skip_trailing_blank_rows(buf, first_content_row, node_last_row),
   }
end

return code_block_dto_builder
