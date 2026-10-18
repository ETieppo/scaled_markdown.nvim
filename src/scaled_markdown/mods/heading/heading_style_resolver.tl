local type HeadingConfigProps =
  require 'scaled_markdown.mods.heading.config_props'
local type TextArtStyleProps =
  require 'scaled_markdown.core.types.text_art_style_props'
local RENDERER_ENUM = require 'scaled_markdown.core.enums.renderer_enum'
local type RendererEnum = RENDERER_ENUM.RendererEnum
local gradient_palette =
  require 'scaled_markdown.core.highlight.gradient_palette'

local GRADIENT_START_RATIO <const> = 0
local GRADIENT_END_RATIO <const> = 1

local type StyleConfigProps = HeadingConfigProps.StyleProps
local type StyleResolverProps = function(
  renderer_config: StyleConfigProps,
  level: integer
): TextArtStyleProps

local record heading_style_resolver
end

local function resolve_typeface_style(
  typeface_style_config: StyleConfigProps,
  level: integer
): TextArtStyleProps
  local rows = typeface_style_config.rows_by_level[level]
  if not rows then return nil end

  return {
    font = typeface_style_config.font,
    symbols = typeface_style_config.symbols,
    rows = rows,
  }
end

local function resolve_graphics_style(
  graphics_style_config: StyleConfigProps,
  level: integer
): TextArtStyleProps
  local line_height_cells =
    graphics_style_config.line_height_cells_by_level[level]
  if not line_height_cells then return nil end

  return {
    font = graphics_style_config.font,
    line_height_cells = line_height_cells,
    start_color = gradient_palette.color_at(GRADIENT_START_RATIO),
    end_color = gradient_palette.color_at(GRADIENT_END_RATIO),
  }
end

local function resolve_figure_font_style(
  figure_font_style_config: StyleConfigProps,
  level: integer
): TextArtStyleProps
  local font = figure_font_style_config.fonts_by_level[level]
  if not font then return nil end

  return { font = font }
end

local style_resolver_by_renderer: {RendererEnum: StyleResolverProps} = {
  [RENDERER_ENUM.GRAPHICS] = resolve_graphics_style,
  [RENDERER_ENUM.TYPEFACE] = resolve_typeface_style,
  [RENDERER_ENUM.TOILET] = resolve_figure_font_style,
  [RENDERER_ENUM.FIGLET] = resolve_figure_font_style,
}

function heading_style_resolver.resolve(
  styles_config: {RendererEnum: StyleConfigProps},
  level: integer
): {RendererEnum: TextArtStyleProps}
  local style_by_renderer: {RendererEnum: TextArtStyleProps} = {}

  for renderer, resolve_style in pairs(style_resolver_by_renderer) do
    local renderer_config = styles_config[renderer]
    if renderer_config then
      style_by_renderer[renderer] = resolve_style(renderer_config, level)
    end
  end

  return style_by_renderer
end

return heading_style_resolver
