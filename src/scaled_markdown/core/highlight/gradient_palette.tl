local CORE_CONSTANTS = require 'scaled_markdown.core.constants'
local GRADIENT_VARIANT_ENUM =
  require 'scaled_markdown.core.enums.gradient_variant_enum'
local type GradientVariantEnum = GRADIENT_VARIANT_ENUM.GradientVariantEnum
local color_math = require 'scaled_markdown.core.highlight.color_math'
local config_store = require 'scaled_markdown.core.config.config_store'
local theme_color_resolver =
  require 'scaled_markdown.core.highlight.theme_color_resolver'

local MINIMUM_STEPS <const> = 2
local FILL_GROUP_SUFFIX <const> = 'Fill'
local FALLBACK_FILL_FOREGROUND <const> = '#0b0b12'
local NORMAL_HIGHLIGHT <const> = 'Normal'
local THEME_START_GROUPS <const>: {string} =
  { '@markup.heading.1.markdown', 'Title', 'Function' }
local THEME_END_GROUPS <const>: {string} =
  { '@markup.heading.2.markdown', 'Statement', 'Keyword' }
local FALLBACK_COLORS <const>: {string} = {
  '#6e4a0e',
  '#b8862b',
  '#f6dc8a',
  '#fff6d0',
  '#d4a13c',
}

local record gradient_palette
end

local resolved_colors: {string} = FALLBACK_COLORS

local group_names_by_variant: {GradientVariantEnum: {string}} = {
  [GRADIENT_VARIANT_ENUM.FOREGROUND] = {},
  [GRADIENT_VARIANT_ENUM.FILL] = {},
}

local function clamp_ratio(
  ratio: number
): number return math.min(1, math.max(0, ratio)) end

local function normalize_colors(colors: string | {string}): {string}
  if colors is string then return { colors } end
  if colors is {string} and #colors > 0 then return colors end
  return nil
end

local function resolve_step_count(): integer
  return math.max(MINIMUM_STEPS, config_store.get().gradient.steps)
end

local function resolve_fill_foreground(): string
  local configured_color = config_store.get().gradient.fill_foreground
  if configured_color then return configured_color end
  return theme_color_resolver.resolve_background(NORMAL_HIGHLIGHT)
    or FALLBACK_FILL_FOREGROUND
end

local function resolve_theme_colors(): {string}
  local theme_start_color =
    theme_color_resolver.resolve_foreground(THEME_START_GROUPS)
  local theme_end_color =
    theme_color_resolver.resolve_foreground(THEME_END_GROUPS)

  if not theme_start_color or not theme_end_color then return nil end
  if theme_start_color == theme_end_color then return nil end
  return { theme_start_color, theme_end_color }
end

local function resolve_gradient_colors(): {string}
  return normalize_colors(config_store.get().gradient.colors)
    or resolve_theme_colors()
    or FALLBACK_COLORS
end

local function resolve_group_names(variant?: GradientVariantEnum): {string}
  return group_names_by_variant[variant or GRADIENT_VARIANT_ENUM.FOREGROUND]
end

function gradient_palette.color_at(ratio: number): string
  return color_math.interpolate_hex(resolved_colors, clamp_ratio(ratio))
end

function gradient_palette.define_groups()
  resolved_colors = resolve_gradient_colors()
  local step_count = resolve_step_count()
  local fill_foreground = resolve_fill_foreground()
  group_names_by_variant[GRADIENT_VARIANT_ENUM.FOREGROUND] = {}
  group_names_by_variant[GRADIENT_VARIANT_ENUM.FILL] = {}

  for step_index = 1, step_count do
    local color = gradient_palette.color_at((step_index - 1) / (step_count - 1))
    local foreground_group = CORE_CONSTANTS.GRADIENT_HIGHLIGHT_PREFIX
      .. step_index
    local fill_group = CORE_CONSTANTS.GRADIENT_HIGHLIGHT_PREFIX
      .. FILL_GROUP_SUFFIX
      .. step_index

    vim.api.nvim_set_hl(0, foreground_group, { fg = color, bold = true })
    vim.api.nvim_set_hl(
      0,
      fill_group,
      { fg = fill_foreground, bg = color, bold = true }
    )
    group_names_by_variant[GRADIENT_VARIANT_ENUM.FOREGROUND][step_index] =
      foreground_group
    group_names_by_variant[GRADIENT_VARIANT_ENUM.FILL][step_index] = fill_group
  end
end

function gradient_palette.group_at(
  ratio: number,
  variant?: GradientVariantEnum
): string
  if #resolve_group_names(variant) == 0 then
    gradient_palette.define_groups()
  end

  local group_names = resolve_group_names(variant)
  local step_index = math.floor(clamp_ratio(ratio) * (#group_names - 1) + 0.5)
    + 1
  return group_names[step_index]
end

function gradient_palette.group_for_position(
  position: integer,
  total: integer,
  variant?: GradientVariantEnum
): string
  if total <= 1 then return gradient_palette.group_at(0, variant) end
  return gradient_palette.group_at(position / (total - 1), variant)
end

return gradient_palette
