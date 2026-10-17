local type ConfigProps = require 'scaled_markdown.core.types.config_props'
local type ModConfigProps =
  require 'scaled_markdown.core.types.mod_config_props'
local DEFAULT_CONFIG = require 'scaled_markdown.core.config.default_config'
local RENDERER_ENUM = require 'scaled_markdown.core.enums.renderer_enum'
local type RendererEnum = RENDERER_ENUM.RendererEnum

local record config_store
end

local current_config: ConfigProps = vim.deepcopy(DEFAULT_CONFIG)

local function is_valid_renderer(renderer: any): boolean
  return vim.tbl_contains(
    vim.tbl_values(RENDERER_ENUM as {string: any}),
    renderer
  )
end

local function validate_config(config: ConfigProps)
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

function config_store.setup(
  user_config: ConfigProps,
  mod_default_configs: {string: ModConfigProps}
): ConfigProps
  local merged_config = vim.tbl_deep_extend(
    'force',
    vim.deepcopy(DEFAULT_CONFIG),
    user_config or {}
  )

  for mod_name, mod_default_config in pairs(mod_default_configs) do
    local mod_user_config: ModConfigProps = merged_config.mods[mod_name] or {}
    local mod_base_config =
      vim.tbl_extend(
        'force',
        { enabled = true } as ModConfigProps,
        mod_default_config
      )
    merged_config.mods[mod_name] =
      vim.tbl_deep_extend('force', mod_base_config, mod_user_config)
  end

  validate_config(merged_config)
  current_config = merged_config
  return current_config
end

function config_store.get(): ConfigProps return current_config end

function config_store.get_mod_config(mod_name: string): ModConfigProps
  return current_config.mods[mod_name] or { enabled = true } as ModConfigProps
end

function config_store.is_valid_renderer(renderer: any): boolean
  return is_valid_renderer(renderer)
end

function config_store.set_renderer(renderer: RendererEnum)
  vim.validate('renderer', renderer, is_valid_renderer, 'a RendererEnum value')
  current_config.renderer = renderer
end

return config_store
