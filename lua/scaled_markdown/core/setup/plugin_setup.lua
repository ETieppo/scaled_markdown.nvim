local autocmd_registry = require 'scaled_markdown.core.autocmd.autocmd_registry'
local buffer_attachment =
  require 'scaled_markdown.core.buffer.buffer_attachment'
local config_store = require 'scaled_markdown.core.config.config_store'
local highlight_setup = require 'scaled_markdown.core.setup.highlight_setup'
local mod_registry = require 'scaled_markdown.core.registry.mod_registry'
local terminal_capability =
  require 'scaled_markdown.core.terminal.terminal_capability'
local tmux_client = require 'scaled_markdown.core.terminal.tmux_client'
local text_art_service =
  require 'scaled_markdown.core.text_art.text_art_service'
local user_command = require 'scaled_markdown.core.command.user_command'

---@class plugin_setup
local plugin_setup = {}

local function refresh_on_terminal_change()
  if not tmux_client.is_inside() then return end
  local was_supported = terminal_capability.supports_kitty_graphics()
  tmux_client.reset()
  if terminal_capability.supports_kitty_graphics() ~= was_supported then
    text_art_service.clear_cache()
    buffer_attachment.schedule_refresh_all()
  end
end

local function release_terminal_resources()
  text_art_service.clear_cache()
  tmux_client.restore_passthrough()
end

---@param user_config? ConfigProps
---@param mod_props_list ModProps[]
function plugin_setup.run(user_config, mod_props_list)
  tmux_client.reset()
  mod_registry.register_all(mod_props_list)
  config_store.setup(user_config, mod_registry.collect_default_configs())
  text_art_service.clear_cache()
  text_art_service.set_ready_listener(buffer_attachment.schedule_refresh_all)
  highlight_setup.apply()
  user_command.register()
  autocmd_registry.register(function()
    text_art_service.clear_cache()
    highlight_setup.apply()
  end, release_terminal_resources, refresh_on_terminal_change)
  autocmd_registry.attach_existing_buffers()
end

return plugin_setup
