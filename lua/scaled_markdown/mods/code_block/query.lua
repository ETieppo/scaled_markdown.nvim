local CODE_BLOCK_CAPTURE_ENUM =
  require 'scaled_markdown.mods.code_block.code_block_capture_enum'

local CODE_BLOCK_QUERY = ([[
(fenced_code_block) @%s
(indented_code_block) @%s
]]):format(CODE_BLOCK_CAPTURE_ENUM.FENCED, CODE_BLOCK_CAPTURE_ENUM.INDENTED)

return CODE_BLOCK_QUERY
