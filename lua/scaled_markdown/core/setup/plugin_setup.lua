local autocmd_registry = require 'scaled_markdown.core.autocmd.autocmd_registry'
local buffer_attachment =
  require 'scaled_markdown.core.buffer.buffer_attachment'
local config_store = require 'scaled_markdown.core.config.config_store'
local highlight_setup = require 'scaled_markdown.core.setup.highlight_setup'
local mod_registry = require 'scaled_markdown.core.registry.mod_registry'
local text_art_service =
  require 'scaled_markdown.core.text_art.text_art_service'
local user_command = require 'scaled_markdown.core.command.user_command'

---@class plugin_setup
local plugin_setup = {}

---@param user_config? ConfigProps
---@param mod_props_list ModProps[]
function plugin_setup.run(user_config, mod_props_list)
  mod_registry.register_all(mod_props_list)
  config_store.setup(user_config, mod_registry.collect_default_configs())
  text_art_service.clear_cache()
  text_art_service.set_ready_listener(buffer_attachment.schedule_refresh_all)
  highlight_setup.apply()
  user_command.register()
  autocmd_registry.register(function()
    text_art_service.clear_cache()
    highlight_setup.apply()
  end, text_art_service.clear_cache)
  autocmd_registry.attach_existing_buffers()
end

return plugin_setup
