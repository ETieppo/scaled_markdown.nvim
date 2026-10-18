local type ModConfigProps =
  require 'scaled_markdown.core.types.mod_config_props'
local HEADING_LINE_STYLE_ENUM =
  require 'scaled_markdown.mods.heading.heading_line_style_enum'
local type HeadingLineStyleEnum = HEADING_LINE_STYLE_ENUM.HeadingLineStyleEnum
local RENDERER_ENUM = require 'scaled_markdown.core.enums.renderer_enum'
local type RendererEnum = RENDERER_ENUM.RendererEnum

local record HeadingConfigProps is ModConfigProps
  record PillCapsProps
    left: string
    right: string
  end

  record StyleProps
    font: string
    symbols: string
    rows_by_level: {integer}
    line_height_cells_by_level: {number}
    fonts_by_level: {string}
  end

  icons_by_level: {string}
  pill_caps: PillCapsProps
  line_styles_by_level: {HeadingLineStyleEnum}
  styles: {RendererEnum: StyleProps}
end

return HeadingConfigProps
