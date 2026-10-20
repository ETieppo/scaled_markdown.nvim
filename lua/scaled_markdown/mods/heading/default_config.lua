local HEADING_LINE_STYLE_ENUM =
  require 'scaled_markdown.mods.heading.heading_line_style_enum'
local RENDERER_ENUM = require 'scaled_markdown.core.enums.renderer_enum'

---@type HeadingConfigProps
local DEFAULT_HEADING_CONFIG = {
  icons_by_level = { '󰉫', '󰉬', '󰉭', '󰉮', '󰉯', '󰉰' },
  pill_caps = { left = '', right = '' },
  line_styles_by_level = {
    HEADING_LINE_STYLE_ENUM.PILL,
    HEADING_LINE_STYLE_ENUM.PILL,
    HEADING_LINE_STYLE_ENUM.PILL,
    HEADING_LINE_STYLE_ENUM.PILL,
    HEADING_LINE_STYLE_ENUM.ACCENT,
    HEADING_LINE_STYLE_ENUM.MUTED,
  },
  styles = {
    [RENDERER_ENUM.GRAPHICS] = {
      font = 'FreeSans:bold',
      line_height_cells_by_level = { 3, 2, 1.5 },
    },
    [RENDERER_ENUM.TYPEFACE] = {
      font = 'FreeSans:bold',
      rows_by_level = { 7, 5, 4 },
    },
    [RENDERER_ENUM.TOILET] = {
      fonts_by_level = { 'mono12', 'mono9', 'smblock' },
    },
    [RENDERER_ENUM.FIGLET] = {
      fonts_by_level = { 'big', 'standard', 'small' },
    },
  },
}

return DEFAULT_HEADING_CONFIG
