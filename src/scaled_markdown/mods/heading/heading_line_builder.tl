local type HeadingConfigProps =
  require 'scaled_markdown.mods.heading.config_props'
local type HeadingProps = require 'scaled_markdown.mods.heading.heading_props'
local GRADIENT_VARIANT_ENUM =
  require 'scaled_markdown.core.enums.gradient_variant_enum'
local HEADING_LINE_STYLE_ENUM =
  require 'scaled_markdown.mods.heading.heading_line_style_enum'
local type HeadingLineStyleEnum = HEADING_LINE_STYLE_ENUM.HeadingLineStyleEnum
local gradient_chunks = require 'scaled_markdown.core.highlight.gradient_chunks'
local heading_highlight = require 'scaled_markdown.mods.heading.highlight'

local LABEL_FORMAT <const> = '%s %s'
local PILL_BODY_FORMAT <const> = ' %s '
local BUILDER_NAME_BY_LINE_STYLE <const>: {HeadingLineStyleEnum: string} = {
  [HEADING_LINE_STYLE_ENUM.PILL] = 'build_pill',
  [HEADING_LINE_STYLE_ENUM.ACCENT] = 'build_accent',
  [HEADING_LINE_STYLE_ENUM.MUTED] = 'build_muted',
}

local type LineStyleBuilderProps = function(
  label: string,
  mod_config: HeadingConfigProps
): {vim.VirtualChunkProps}

local record heading_line_builder
end

local function build_pill(
  label: string,
  mod_config: HeadingConfigProps
): {vim.VirtualChunkProps}
  return gradient_chunks.from_segments {
    { text = mod_config.pill_caps.left },
    {
      text = PILL_BODY_FORMAT:format(label),
      variant = GRADIENT_VARIANT_ENUM.FILL,
    },
    { text = mod_config.pill_caps.right },
  }
end

local function build_accent(label: string): {vim.VirtualChunkProps}
  return gradient_chunks.from_text(label)
end

local function build_muted(label: string): {vim.VirtualChunkProps}
  return { { label, heading_highlight.GROUPS.MUTED } }
end

local line_style_builders: {string: LineStyleBuilderProps} = {
  build_pill = build_pill,
  build_accent = build_accent,
  build_muted = build_muted,
}

local function build_label(
  heading_dto: HeadingProps,
  mod_config: HeadingConfigProps
): string
  local icon = mod_config.icons_by_level[heading_dto.level]
  return icon and LABEL_FORMAT:format(icon, heading_dto.text)
    or heading_dto.text
end

function heading_line_builder.build(
  heading_dto: HeadingProps,
  mod_config: HeadingConfigProps
): {vim.VirtualChunkProps}
  local line_style = mod_config.line_styles_by_level[heading_dto.level]
  local builder_name = BUILDER_NAME_BY_LINE_STYLE[line_style]
    or BUILDER_NAME_BY_LINE_STYLE[HEADING_LINE_STYLE_ENUM.MUTED]
  return line_style_builders[builder_name](
    build_label(heading_dto, mod_config),
    mod_config
  )
end

return heading_line_builder
