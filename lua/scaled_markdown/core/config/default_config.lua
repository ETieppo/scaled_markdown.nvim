local RENDERER_ENUM = require 'scaled_markdown.core.enums.renderer_enum'

---@type ConfigProps
local DEFAULT_CONFIG = {
  enabled = true,
  file_types = { 'markdown' },
  renderer = RENDERER_ENUM.GRAPHICS,
  reveal = {
    cursor_line = true,
    visual_selection = true,
  },
  window_options = {
    conceallevel = 2,
    concealcursor = '',
  },
  gradient = {
    steps = 16,
  },
  terminal = {
    fallback_cell_width_pixels = 10,
    fallback_cell_height_pixels = 22,
  },
  mods = {},
}

return DEFAULT_CONFIG
