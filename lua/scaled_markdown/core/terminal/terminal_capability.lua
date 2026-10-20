local GRAPHICS_PROTOCOL_ENUM =
  require 'scaled_markdown.core.enums.graphics_protocol_enum'
local config_store = require 'scaled_markdown.core.config.config_store'
local terminal_query = require 'scaled_markdown.core.terminal.terminal_query'
local tmux_client = require 'scaled_markdown.core.terminal.tmux_client'

---@type table<string, boolean>
local PLACEHOLDER_TERM_PROGRAMS = { ghostty = true, kitty = true }
---@type string[]
local PLACEHOLDER_TERMINAL_PATTERNS = { 'kitty', 'ghostty' }
---@type integer[]
local MINIMUM_KITTY_PLACEHOLDER_VERSION = { 0, 28, 0 }
local KITTY_NAME = 'kitty'
local VERSION_NUMBER_PATTERN = '%d+'
local TRUE_COLOR_FEATURE = 'RGB'
local NO_TRUE_COLOR_REASON = 'termguicolors is off'
local NO_UI_REASON = 'no UI is attached'
local DISABLED_REASON = 'terminal.graphics_protocol is none'
local UNKNOWN_TERMINAL_REASON =
  'terminal reports neither kitty unicode placeholders nor sixel'
local OLD_KITTY_REASON = 'kitty %s is older than 0.28 (no unicode placeholders)'
local TMUX_UNREACHABLE_REASON = 'tmux client could not be queried'
local TMUX_UNKNOWN_CLIENT_REASON =
  'tmux client terminal has no kitty unicode placeholders (%s); sixel is not used inside tmux'
local TMUX_NO_RGB_REASON =
  "tmux client has no RGB feature; add it with terminal-features (e.g. set -as terminal-features ',xterm*:RGB')"
local TMUX_NO_PASSTHROUGH_REASON =
  'tmux allow-passthrough is off and terminal.allow_tmux_passthrough is false'

---@class terminal_capability
local terminal_capability = {}

---@param text string
---@return boolean
local function matches_placeholder_terminal(text)
  local lowered_text = text:lower()
  for _, pattern in ipairs(PLACEHOLDER_TERMINAL_PATTERNS) do
    if lowered_text:find(pattern, 1, true) then return true end
  end
  return false
end

---@param version string
---@return boolean
local function is_kitty_version_supported(version)
  ---@type integer[]
  local numbers = {}
  for number in version:gmatch(VERSION_NUMBER_PATTERN) do
    numbers[#numbers + 1] = math.floor(tonumber(number) --[[@as number]])
  end
  for index, minimum in ipairs(MINIMUM_KITTY_PLACEHOLDER_VERSION) do
    local number = numbers[index] or 0
    if number ~= minimum then return number > minimum end
  end
  return true
end

---@return boolean
local function matches_placeholder_environment()
  if
    vim.env.KITTY_WINDOW_ID
    or PLACEHOLDER_TERM_PROGRAMS[vim.env.TERM_PROGRAM or '']
  then
    return true
  end
  return matches_placeholder_terminal(vim.env.TERM or '')
end

---@param protocol GraphicsProtocolEnum
---@param is_inside_tmux boolean
---@param unsupported_reason? string
---@return TerminalCapabilityProps
local function build_capability(
  protocol,
  is_inside_tmux,
  unsupported_reason
)
  return {
    protocol = protocol,
    is_inside_tmux = is_inside_tmux,
    unsupported_reason = unsupported_reason,
  }
end

---@return string?
local function find_tmux_unsupported_reason()
  local client_props = tmux_client.probe()
  if not client_props then return TMUX_UNREACHABLE_REASON end
  if
    not matches_placeholder_terminal(client_props.term_name)
    and not matches_placeholder_terminal(client_props.term_type)
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

---@return GraphicsProtocolEnum, string?
local function detect_direct_protocol()
  local identity = terminal_query.identity()
  if identity.name then
    if identity.name == KITTY_NAME and identity.version then
      if not is_kitty_version_supported(identity.version) then
        if identity.has_sixel then return GRAPHICS_PROTOCOL_ENUM.SIXEL end
        return GRAPHICS_PROTOCOL_ENUM.NONE,
          OLD_KITTY_REASON:format(identity.version)
      end
    end
    if matches_placeholder_terminal(identity.name) then
      return GRAPHICS_PROTOCOL_ENUM.KITTY_PLACEHOLDER
    end
  elseif matches_placeholder_environment() then
    return GRAPHICS_PROTOCOL_ENUM.KITTY_PLACEHOLDER
  end
  if identity.has_sixel then return GRAPHICS_PROTOCOL_ENUM.SIXEL end
  return GRAPHICS_PROTOCOL_ENUM.NONE, UNKNOWN_TERMINAL_REASON
end

---@param is_inside_tmux boolean
---@return TerminalCapabilityProps
local function detect_automatically(is_inside_tmux)
  if is_inside_tmux then
    local unsupported_reason = find_tmux_unsupported_reason()
    return build_capability(
      unsupported_reason and GRAPHICS_PROTOCOL_ENUM.NONE
        or GRAPHICS_PROTOCOL_ENUM.KITTY_PLACEHOLDER,
      is_inside_tmux,
      unsupported_reason
    )
  end
  local protocol, unsupported_reason = detect_direct_protocol()
  return build_capability(protocol, is_inside_tmux, unsupported_reason)
end

---@return TerminalCapabilityProps
function terminal_capability.detect()
  local is_inside_tmux = tmux_client.is_inside()
  local terminal_config = config_store.get().terminal --[[@as TerminalProps]]
  local configured_protocol = terminal_config.graphics_protocol
    or GRAPHICS_PROTOCOL_ENUM.AUTO
  if configured_protocol == GRAPHICS_PROTOCOL_ENUM.NONE then
    return build_capability(
      GRAPHICS_PROTOCOL_ENUM.NONE,
      is_inside_tmux,
      DISABLED_REASON
    )
  end
  if not vim.o.termguicolors then
    return build_capability(
      GRAPHICS_PROTOCOL_ENUM.NONE,
      is_inside_tmux,
      NO_TRUE_COLOR_REASON
    )
  end
  if #vim.api.nvim_list_uis() == 0 then
    return build_capability(
      GRAPHICS_PROTOCOL_ENUM.NONE,
      is_inside_tmux,
      NO_UI_REASON
    )
  end
  if configured_protocol ~= GRAPHICS_PROTOCOL_ENUM.AUTO then
    return build_capability(configured_protocol, is_inside_tmux)
  end
  return detect_automatically(is_inside_tmux)
end

---@return GraphicsProtocolEnum
function terminal_capability.protocol()
  return terminal_capability.detect().protocol
end

return terminal_capability
