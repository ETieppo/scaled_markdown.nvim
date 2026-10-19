local GRADIENT_VARIANT_ENUM =
  require 'scaled_markdown.core.enums.gradient_variant_enum'
local HEADING_LINE_STYLE_ENUM =
  require 'scaled_markdown.mods.heading.heading_line_style_enum'
local gradient_chunks = require 'scaled_markdown.core.highlight.gradient_chunks'
local heading_highlight = require 'scaled_markdown.mods.heading.highlight'

local LABEL_FORMAT = '%s %s'
local PILL_BODY_FORMAT = ' %s '
---@type table<HeadingLineStyleEnum, string>
local BUILDER_NAME_BY_LINE_STYLE = {
  [HEADING_LINE_STYLE_ENUM.PILL] = 'build_pill',
  [HEADING_LINE_STYLE_ENUM.ACCENT] = 'build_accent',
  [HEADING_LINE_STYLE_ENUM.MUTED] = 'build_muted',
}

---@alias LineStyleBuilderProps fun(label: string, mod_config: HeadingConfigProps): [string, string][]

---@class heading_line_builder
local heading_line_builder = {}

---@param label string
---@param mod_config HeadingConfigProps
---@return [string, string][]
local function build_pill(label, mod_config)
  return gradient_chunks.from_segments {
    { text = mod_config.pill_caps.left },
    {
      text = PILL_BODY_FORMAT:format(label),
      variant = GRADIENT_VARIANT_ENUM.FILL,
    },
    { text = mod_config.pill_caps.right },
  }
end

---@param label string
---@return [string, string][]
local function build_accent(label) return gradient_chunks.from_text(label) end

---@param label string
---@return [string, string][]
local function build_muted(label)
  return { { label, heading_highlight.GROUPS.MUTED } }
end

---@type table<string, LineStyleBuilderProps>
local line_style_builders = {
  build_pill = build_pill,
  build_accent = build_accent,
  build_muted = build_muted,
}

---@param heading_dto HeadingProps
---@param mod_config HeadingConfigProps
---@return string
local function build_label(heading_dto, mod_config)
  local icon = mod_config.icons_by_level[heading_dto.level]
  return icon and LABEL_FORMAT:format(icon, heading_dto.text)
    or heading_dto.text
end

---@param heading_dto HeadingProps
---@param mod_config HeadingConfigProps
---@return [string, string][]
function heading_line_builder.build(heading_dto, mod_config)
  local line_style = mod_config.line_styles_by_level[heading_dto.level]
  local builder_name = BUILDER_NAME_BY_LINE_STYLE[line_style]
    or BUILDER_NAME_BY_LINE_STYLE[HEADING_LINE_STYLE_ENUM.MUTED]
  return line_style_builders[builder_name](
    build_label(heading_dto, mod_config),
    mod_config
  )
end

return heading_line_builder
