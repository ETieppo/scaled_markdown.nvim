local type HighlightDefinitionsProps =
  require 'scaled_markdown.core.types.highlight_definitions_props'
local type ModConfigProps =
  require 'scaled_markdown.core.types.mod_config_props'
local type ModProps = require 'scaled_markdown.core.types.mod_props'
local type RegisteredModProps =
  require 'scaled_markdown.core.types.registered_mod_props'
local LANGUAGE_ENUM = require 'scaled_markdown.core.enums.language_enum'

local record mod_registry
end

local registered_mods: {RegisteredModProps} = {}

local function is_valid_language(language: any): boolean
  return vim.tbl_contains(
    vim.tbl_values(LANGUAGE_ENUM as {string: any}),
    language
  )
end

local function validate_mod_props(mod_props: ModProps)
  vim.validate('mod_props', mod_props, 'table')
  vim.validate('mod_props.name', mod_props.name, 'string')
  vim.validate(
    'mod_props.language',
    mod_props.language,
    is_valid_language,
    'a LanguageEnum value'
  )
  vim.validate('mod_props.query', mod_props.query, 'string')
  vim.validate('mod_props.render', mod_props.render, 'function')
  vim.validate(
    'mod_props.default_config',
    mod_props.default_config,
    'table',
    true
  )
  vim.validate(
    'mod_props.highlights',
    mod_props.highlights,
    { 'table', 'function' },
    true
  )
end

function mod_registry.register(mod_props: ModProps)
  validate_mod_props(mod_props)
  registered_mods[#registered_mods + 1] = {
    props = mod_props,
    query = vim.treesitter.query.parse(mod_props.language, mod_props.query),
  }
end

function mod_registry.register_all(mod_props_list: {ModProps})
  registered_mods = {}
  for _, mod_props in ipairs(mod_props_list) do
    mod_registry.register(mod_props)
  end
end

function mod_registry.list(): {RegisteredModProps} return registered_mods end

function mod_registry.collect_default_configs(): {string: ModConfigProps}
  local default_configs: {string: ModConfigProps} = {}
  for _, registered_mod in ipairs(registered_mods) do
    default_configs[registered_mod.props.name] =
      registered_mod.props.default_config or {} as ModConfigProps
  end
  return default_configs
end

local function resolve_highlights(
  highlights: HighlightDefinitionsProps | function(): HighlightDefinitionsProps
): HighlightDefinitionsProps
  if highlights is function(): HighlightDefinitionsProps then
    return highlights()
  end
  return highlights or {}
end

function mod_registry.collect_highlights(): HighlightDefinitionsProps
  local highlights: HighlightDefinitionsProps = {}
  for _, registered_mod in ipairs(registered_mods) do
    local mod_highlights = resolve_highlights(registered_mod.props.highlights)
    for group_name, group_props in pairs(mod_highlights) do
      highlights[group_name] = group_props
    end
  end
  return highlights
end

return mod_registry
