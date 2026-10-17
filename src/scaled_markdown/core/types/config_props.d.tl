local type ModConfigProps =
  require 'scaled_markdown.core.types.mod_config_props'
local type WindowOptionsProps =
  require 'scaled_markdown.core.types.window_options_props'
local RENDERER_ENUM = require 'scaled_markdown.core.enums.renderer_enum'
local type RendererEnum = RENDERER_ENUM.RendererEnum

local record ConfigProps
  record RevealProps
    cursor_line: boolean
    visual_selection: boolean
  end

  record GradientProps
    steps: integer
    colors: string | {string}
    fill_foreground: string
  end

  record TerminalProps
    cell_width_pixels: integer
    cell_height_pixels: integer
    fallback_cell_width_pixels: integer
    fallback_cell_height_pixels: integer
  end

  enabled: boolean
  file_types: {string}
  renderer: RendererEnum
  reveal: RevealProps
  window_options: WindowOptionsProps
  gradient: GradientProps
  terminal: TerminalProps
  mods: {string: ModConfigProps}
end

return ConfigProps
