local config_store = require 'scaled_markdown.core.config.config_store'
local tmux_client = require 'scaled_markdown.core.terminal.tmux_client'

---@type table<string, boolean>
local KITTY_GRAPHICS_TERM_PROGRAMS =
  { ghostty = true, WezTerm = true, kitty = true }
---@type string[]
local KITTY_GRAPHICS_TERM_PATTERNS = { 'kitty', 'ghostty', 'wezterm' }
local TRUE_COLOR_FEATURE = 'RGB'
local NO_TRUE_COLOR_REASON = 'termguicolors is off'
local NO_UI_REASON = 'no UI is attached'
local UNKNOWN_TERMINAL_REASON = 'terminal is not kitty, ghostty or wezterm'
local TMUX_UNREACHABLE_REASON = 'tmux client could not be queried'
local TMUX_UNKNOWN_CLIENT_REASON =
  'tmux client terminal is not kitty, ghostty or wezterm (%s)'
local TMUX_NO_RGB_REASON =
  "tmux client has no RGB feature; add it with terminal-features (e.g. set -as terminal-features ',xterm*:RGB')"
local TMUX_NO_PASSTHROUGH_REASON =
  'tmux allow-passthrough is off and terminal.allow_tmux_passthrough is false'

---@class terminal_capability
local terminal_capability = {}

---@param text string
---@return boolean
local function matches_known_pattern(text)
  local lowered_text = text:lower()
  for _, pattern in ipairs(KITTY_GRAPHICS_TERM_PATTERNS) do
    if lowered_text:find(pattern, 1, true) then return true end
  end
  return false
end

---@return boolean
local function matches_known_terminal()
  if
    vim.env.KITTY_WINDOW_ID
    or KITTY_GRAPHICS_TERM_PROGRAMS[vim.env.TERM_PROGRAM or '']
  then
    return true
  end
  return matches_known_pattern(vim.env.TERM or '')
end

---@param unsupported_reason? string
---@param is_inside_tmux boolean
---@return TerminalCapabilityProps
local function build_capability(unsupported_reason, is_inside_tmux)
  return {
    supports_kitty_graphics = unsupported_reason == nil,
    is_inside_tmux = is_inside_tmux,
    unsupported_reason = unsupported_reason,
  }
end

---@return string?
local function find_tmux_unsupported_reason()
  local client_props = tmux_client.probe()
  if not client_props then return TMUX_UNREACHABLE_REASON end
  if
    not matches_known_pattern(client_props.term_name)
    and not matches_known_pattern(client_props.term_type)
  then
    return TMUX_UNKNOWN_CLIENT_REASON:format(client_props.term_name)
  end
  if not client_props.features[TRUE_COLOR_FEATURE] then
    return TMUX_NO_RGB_REASON
  end
  local terminal_config = config_store.get().terminal --[[@as TerminalProps]]
  if
    not tmux_client.ensure_passthrough(
      terminal_config.allow_tmux_passthrough == true
    )
  then
    return TMUX_NO_PASSTHROUGH_REASON
  end
  return nil
end

---@return TerminalCapabilityProps
function terminal_capability.detect()
  local is_inside_tmux = tmux_client.is_inside()
  if not vim.o.termguicolors then
    return build_capability(NO_TRUE_COLOR_REASON, is_inside_tmux)
  end
  if #vim.api.nvim_list_uis() == 0 then
    return build_capability(NO_UI_REASON, is_inside_tmux)
  end
  if is_inside_tmux then
    return build_capability(find_tmux_unsupported_reason(), is_inside_tmux)
  end
  return build_capability(
    not matches_known_terminal() and UNKNOWN_TERMINAL_REASON or nil,
    is_inside_tmux
  )
end

---@return boolean
function terminal_capability.supports_kitty_graphics()
  return terminal_capability.detect().supports_kitty_graphics
end

return terminal_capability
