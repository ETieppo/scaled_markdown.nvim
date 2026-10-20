local LANGUAGE_ICONS = require 'scaled_markdown.mods.code_block.language_icons'

---@type CodeBlockConfigProps
local DEFAULT_CODE_BLOCK_CONFIG = {
  min_width = 40,
  horizontal_padding = 1,
  language_icons = LANGUAGE_ICONS,
  default_language_icon = '\u{F121} ',
}

return DEFAULT_CODE_BLOCK_CONFIG
