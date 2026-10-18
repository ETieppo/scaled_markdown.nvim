local type CodeBlockConfigProps =
  require 'scaled_markdown.mods.code_block.config_props'

local DEFAULT_CODE_BLOCK_CONFIG <const>: CodeBlockConfigProps = {
  min_width = 40,
  horizontal_padding = 1,
}

return DEFAULT_CODE_BLOCK_CONFIG
