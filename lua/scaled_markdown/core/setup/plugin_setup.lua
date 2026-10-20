local autocmd_registry = require 'scaled_markdown.core.autocmd.autocmd_registry'
local buffer_attachment =
  require 'scaled_markdown.core.buffer.buffer_attachment'
local config_store = require 'scaled_markdown.core.config.config_store'
local highlight_setup = require 'scaled_markdown.core.setup.highlight_setup'
local mod_registry = require 'scaled_markdown.core.registry.mod_registry'
local neovim_version = require 'scaled_markdown.core.setup.neovim_version'
local positioned_image_painter =
  require 'scaled_markdown.core.render.positioned_image_painter'
local terminal_capability =
  require 'scaled_markdown.core.terminal.terminal_capability'
local terminal_query = require 'scaled_markdown.core.terminal.terminal_query'
local tmux_client = require 'scaled_markdown.core.terminal.tmux_client'
local text_art_service =
  require 'scaled_markdown.core.text_art.text_art_service'
local user_command = require 'scaled_markdown.core.command.user_command'

local UNSUPPORTED_NEOVIM_MESSAGE =
  'scaled_markdown.nvim requires neovim %s or newer'

---@class plugin_setup
local plugin_setup = {}

---@param refresh_terminal_state fun()
local function refresh_when_protocol_changes(refresh_terminal_state)
  local previous_protocol = terminal_capability.protocol()
  refresh_terminal_state()
  if terminal_capability.protocol() ~= previous_protocol then
    positioned_image_painter.reset()
    text_art_service.clear_cache()
    buffer_attachment.schedule_refresh_all()
  end
end

local function refresh_on_terminal_change()
  positioned_image_painter.request_repaint()
  if not tmux_client.is_inside() then return end
  refresh_when_protocol_changes(tmux_client.reset)
end

local function refresh_on_terminal_response()
  refresh_when_protocol_changes(function() end)
end

local function release_terminal_resources()
  text_art_service.clear_cache()
  tmux_client.restore_passthrough()
end

---@param user_config? ConfigProps
---@param mod_props_list ModProps[]
function plugin_setup.run(user_config, mod_props_list)
  if not neovim_version.is_supported() then
    vim.notify(
      UNSUPPORTED_NEOVIM_MESSAGE:format(neovim_version.MINIMUM_VERSION_TEXT),
      vim.log.levels.ERROR
    )
    return
  end
  tmux_client.reset()
  positioned_image_painter.reset()
  mod_registry.register_all(mod_props_list)
  config_store.setup(user_config, mod_registry.collect_default_configs())
  text_art_service.clear_cache()
  text_art_service.set_ready_listener(buffer_attachment.schedule_refresh_all)
  highlight_setup.apply()
  user_command.register()
  autocmd_registry.register {
    on_colorscheme_changed = function()
      text_art_service.clear_cache()
      highlight_setup.apply()
    end,
    on_exit = release_terminal_resources,
    on_terminal_changed = refresh_on_terminal_change,
    on_layout_changed = positioned_image_painter.request_repaint,
  }
  terminal_query.start(refresh_on_terminal_response)
  autocmd_registry.attach_existing_buffers()
end

return plugin_setup
