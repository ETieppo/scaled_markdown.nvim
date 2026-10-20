local LANGUAGE_ENUM = require 'scaled_markdown.core.enums.language_enum'

---@class mod_registry
local mod_registry = {}

---@type RegisteredModProps[]
local registered_mods = {}

---@param language any
---@return boolean
local function is_valid_language(language)
  return vim.tbl_contains(vim.tbl_values(LANGUAGE_ENUM), language)
end

---@param mod_props ModProps
local function validate_mod_props(mod_props)
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
  vim.validate(
    'mod_props.decorate_line_prefix',
    mod_props.decorate_line_prefix,
    'function',
    true
  )
end

---@param mod_props ModProps
function mod_registry.register(mod_props)
  validate_mod_props(mod_props)
  registered_mods[#registered_mods + 1] = {
    props = mod_props,
    query = vim.treesitter.query.parse(mod_props.language, mod_props.query),
  }
end

---@param mod_props_list ModProps[]
function mod_registry.register_all(mod_props_list)
  registered_mods = {}
  for _, mod_props in ipairs(mod_props_list) do
    mod_registry.register(mod_props)
  end
end

---@return RegisteredModProps[]
function mod_registry.list() return registered_mods end

---@return table<string, ModConfigProps>
function mod_registry.collect_default_configs()
  ---@type table<string, ModConfigProps>
  local default_configs = {}
  for _, registered_mod in ipairs(registered_mods) do
    default_configs[registered_mod.props.name] = registered_mod.props.default_config
      or {}
  end
  return default_configs
end

---@param highlights HighlightDefinitionsProps|(fun(): HighlightDefinitionsProps)
---@return HighlightDefinitionsProps
local function resolve_highlights(highlights)
  if type(highlights) == 'function' then return highlights() end
  return highlights or {}
end

---@return HighlightDefinitionsProps
function mod_registry.collect_highlights()
  ---@type HighlightDefinitionsProps
  local highlights = {}
  for _, registered_mod in ipairs(registered_mods) do
    local mod_highlights = resolve_highlights(registered_mod.props.highlights)
    for group_name, group_props in pairs(mod_highlights) do
      highlights[group_name] = group_props
    end
  end
  return highlights
end

return mod_registry
