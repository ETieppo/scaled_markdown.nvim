local config_store = require 'scaled_markdown.core.config.config_store'
local mod_registry = require 'scaled_markdown.core.registry.mod_registry'
local render_pipeline = require 'scaled_markdown.core.render.render_pipeline'
local scaled_markdown = require 'scaled_markdown'
local text_art_service =
  require 'scaled_markdown.core.text_art.text_art_service'

local TEXT_ART_WAIT_MS = 10000
local MAX_SETTLE_ROUNDS = 6
---@type ConfigProps
local PLAIN_CONFIG = { renderer = 'plain' }
---@type RevealProps
local NO_REVEAL = {
  cursor_line = false,
  visual_selection = false,
}

---@class plugin_session
local plugin_session = {}

---@param config? ConfigProps
function plugin_session.start(config)
  scaled_markdown.setup(config or vim.deepcopy(PLAIN_CONFIG))
end

---@return string[]
function plugin_session.mod_names()
  ---@type string[]
  local names = {}
  for _, registered_mod in ipairs(mod_registry.list()) do
    names[#names + 1] = registered_mod.props.name
  end
  return names
end

---@param mod_name string
---@param mod_config? table<string, any>
---@param base_config? ConfigProps
function plugin_session.start_with_only(mod_name, mod_config, base_config)
  plugin_session.start()
  ---@type table<string, ModConfigProps>
  local mods_config = {}
  for _, name in ipairs(plugin_session.mod_names()) do
    mods_config[name] = { enabled = name == mod_name }
  end
  mods_config[mod_name] =
    vim.tbl_extend('force', { enabled = true }, mod_config or {})
  ---@type ConfigProps
  local session_config = vim.tbl_extend(
    'force',
    { renderer = 'plain', reveal = NO_REVEAL, mods = mods_config },
    base_config or {}
  )
  plugin_session.start(session_config)
end

---@param buf integer
function plugin_session.render(buf) render_pipeline.render(buf) end

---@return boolean
function plugin_session.wait_for_text_art()
  return vim.wait(
    TEXT_ART_WAIT_MS,
    ---@return boolean
    function() return not text_art_service.has_pending() end
  )
end

---@param buf integer
---@return boolean
function plugin_session.render_until_settled(buf)
  for _ = 1, MAX_SETTLE_ROUNDS do
    plugin_session.render(buf)
    if not text_art_service.has_pending() then return true end
    plugin_session.wait_for_text_art()
  end
  return false
end

---@param mod_name string
---@return ModConfigProps
function plugin_session.mod_config(mod_name)
  return config_store.get_mod_config(mod_name)
end

return plugin_session
