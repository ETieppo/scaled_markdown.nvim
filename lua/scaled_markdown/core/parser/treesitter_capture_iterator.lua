


local LANGUAGE_ENUM = require('scaled_markdown.core.enums.language_enum')
local capture_dto_builder =
require('scaled_markdown.core.parser.capture_dto_builder')

local treesitter_capture_iterator = {}


local function intersects_rows(
   tree,
   start_row,
   end_row)

   local tree_start_row, _, tree_end_row = tree:root():range()
   return tree_start_row < end_row and tree_end_row >= start_row
end

function treesitter_capture_iterator.collect_trees_by_language(
   buf,
   start_row,
   end_row)

   local ok, parser = pcall(
   vim.treesitter.get_parser,
   buf,
   LANGUAGE_ENUM.MARKDOWN,
   { error = false })

   if not ok or not parser then return nil end
   parser:parse({ start_row, end_row })
   local trees_by_language = {}
   parser:for_each_tree(function(
      tree,
      language_tree)

      if not intersects_rows(tree, start_row, end_row) then return end
      local language = language_tree:lang()
      trees_by_language[language] = trees_by_language[language] or {}
      table.insert(trees_by_language[language], tree)
   end)
   return trees_by_language
end

function treesitter_capture_iterator.for_each_capture(
   trees_by_language,
   registered_mod,
   buf,
   start_row,
   end_row,
   callback)

   local query = registered_mod.query
   local trees = trees_by_language[registered_mod.props.language] or {}
   for _, tree in ipairs(trees) do
      for capture_id, node in
query:iter_captures(tree:root(), buf, start_row, end_row) do

         callback(capture_dto_builder.build(buf, query.captures[capture_id], node))
      end
   end
end

return treesitter_capture_iterator
