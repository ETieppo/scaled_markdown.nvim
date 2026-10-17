local type CaptureProps = require 'scaled_markdown.core.types.capture_props'
local type RegisteredModProps =
  require 'scaled_markdown.core.types.registered_mod_props'
local LANGUAGE_ENUM = require 'scaled_markdown.core.enums.language_enum'
local capture_dto_builder =
  require 'scaled_markdown.core.parser.capture_dto_builder'

local record treesitter_capture_iterator
end

local function intersects_rows(
  tree: vim.TSTreeProps,
  start_row: integer,
  end_row: integer
): boolean
  local tree_start_row, _, tree_end_row = tree:root():range()
  return tree_start_row < end_row and tree_end_row >= start_row
end

function treesitter_capture_iterator.collect_trees_by_language(
  buf: integer,
  start_row: integer,
  end_row: integer
): {string: {vim.TSTreeProps}}
  local ok, parser = pcall(
    vim.treesitter.get_parser,
    buf,
    LANGUAGE_ENUM.MARKDOWN,
    { error = false }
  )
  if not ok or not parser then return nil end
  parser:parse { start_row, end_row }
  local trees_by_language: {string: {vim.TSTreeProps}} = {}
  parser:for_each_tree(function(
    tree: vim.TSTreeProps,
    language_tree: vim.LanguageTreeProps
  )
    if not intersects_rows(tree, start_row, end_row) then return end
    local language = language_tree:lang()
    trees_by_language[language] = trees_by_language[language] or {}
    table.insert(trees_by_language[language], tree)
  end)
  return trees_by_language
end

function treesitter_capture_iterator.for_each_capture(
  trees_by_language: {string: {vim.TSTreeProps}},
  registered_mod: RegisteredModProps,
  buf: integer,
  start_row: integer,
  end_row: integer,
  callback: function(CaptureProps)
)
  local query = registered_mod.query
  local trees = trees_by_language[registered_mod.props.language] or {}
  for _, tree in ipairs(trees) do
    for capture_id, node in
      query:iter_captures(tree:root(), buf, start_row, end_row)
    do
      callback(capture_dto_builder.build(buf, query.captures[capture_id], node))
    end
  end
end

return treesitter_capture_iterator
