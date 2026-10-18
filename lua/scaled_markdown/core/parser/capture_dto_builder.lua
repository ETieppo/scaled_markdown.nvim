

local capture_dto_builder = {}


function capture_dto_builder.build(
   buf,
   capture_name,
   node)

   local start_row, start_col, end_row, end_col = node:range()
   return {
      name = capture_name,
      node = node,
      start_row = start_row,
      start_col = start_col,
      end_row = end_row,
      end_col = end_col,
      text = vim.treesitter.get_node_text(node, buf),
   }
end

return capture_dto_builder
