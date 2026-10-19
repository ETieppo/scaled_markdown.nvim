local DEFAULT_CONFIG = require 'scaled_markdown.core.config.default_config'
local RENDERER_ENUM = require 'scaled_markdown.core.enums.renderer_enum'

---@class config_store
local config_store = {}

---@type ConfigProps
local current_config = vim.deepcopy(DEFAULT_CONFIG)

---@param renderer any
---@return boolean
local function is_valid_renderer(renderer)
  return vim.tbl_contains(vim.tbl_values(RENDERER_ENUM), renderer)
end

---@param config ConfigProps
local function validate_config(config)
  vim.validate('enabled', config.enabled, 'boolean')
  vim.validate('file_types', config.file_types, 'table')
  vim.validate(
    'renderer',
    config.renderer,
    is_valid_renderer,
    'a RendererEnum value'
  )
  vim.validate('reveal', config.reveal, 'table')
  vim.validate('window_options', config.window_options, 'table')
  vim.validate('gradient', config.gradient, 'table')
  vim.validate('terminal', config.terminal, 'table')
  vim.validate('mods', config.mods, 'table')
end

---@param user_config? ConfigProps
---@param mod_default_configs table<string, ModConfigProps>
---@return ConfigProps
function config_store.setup(user_config, mod_default_configs)
  local merged_config = vim.tbl_deep_extend(
    'force',
    vim.deepcopy(DEFAULT_CONFIG),
    user_config or {}
  )

  for mod_name, mod_default_config in pairs(mod_default_configs) do
    ---@type ModConfigProps
    local mod_user_config = merged_config.mods[mod_name] or {}
    local mod_base_config =
      vim.tbl_extend('force', { enabled = true }, mod_default_config)
    merged_config.mods[mod_name] =
      vim.tbl_deep_extend('force', mod_base_config, mod_user_config)
  end

  validate_config(merged_config)
  current_config = merged_config
  return current_config
end

---@return ConfigProps
function config_store.get() return current_config end

---@param mod_name string
---@return ModConfigProps
function config_store.get_mod_config(mod_name)
  return current_config.mods[mod_name] or { enabled = true }
end

---@param renderer any
---@return boolean
function config_store.is_valid_renderer(renderer)
  return is_valid_renderer(renderer)
end

---@param renderer RendererEnum
function config_store.set_renderer(renderer)
  vim.validate('renderer', renderer, is_valid_renderer, 'a RendererEnum value')
  current_config.renderer = renderer
end

return config_store
