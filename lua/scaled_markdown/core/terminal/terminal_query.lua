local CORE_CONSTANTS = require 'scaled_markdown.core.constants'

local PRIMARY_ATTRIBUTES_QUERY = '\27[c'
local VERSION_QUERY = '\27[>0q'
local PRIMARY_ATTRIBUTES_PATTERN = '^\27%[%?([%d;]*)c$'
local VERSION_PATTERN = '^\27P>|(.-)\27?\\?$'
---@type string[]
local NAME_AND_VERSION_PATTERNS =
  { '^([%w%-_]+)%(([^)]*)%)', '^([%w%-_]+)%s+(%S+)' }
local SIXEL_ATTRIBUTE = '4'
local ATTRIBUTE_SEPARATOR = ';'
local AUGROUP_NAME = CORE_CONSTANTS.AUGROUP_NAME .. 'TerminalQuery'

---@class terminal_query
local terminal_query = {}

---@type TerminalIdentityProps
local identity = {}
---@type (fun())?
local change_listener = nil

---@param attributes string
---@return boolean
local function contains_sixel_attribute(attributes)
  for _, attribute in
    ipairs(vim.split(attributes, ATTRIBUTE_SEPARATOR, { plain = true }))
  do
    if attribute == SIXEL_ATTRIBUTE then return true end
  end
  return false
end

---@param version_text string
---@return string, string?
local function split_name_and_version(version_text)
  for _, pattern in ipairs(NAME_AND_VERSION_PATTERNS) do
    local name, version = version_text:match(pattern)
    if name then return name:lower(), version end
  end
  return version_text:lower(), nil
end

---@param sequence string
---@return boolean
function terminal_query.handle_response(sequence)
  local attributes = sequence:match(PRIMARY_ATTRIBUTES_PATTERN)
  if attributes then
    local has_sixel = contains_sixel_attribute(attributes)
    if identity.has_sixel == has_sixel then return false end
    identity.has_sixel = has_sixel
    return true
  end
  local version_text = sequence:match(VERSION_PATTERN)
  if version_text and version_text ~= '' then
    local name, version = split_name_and_version(version_text)
    if identity.name == name and identity.version == version then
      return false
    end
    identity.name, identity.version = name, version
    return true
  end
  return false
end

---@return TerminalIdentityProps
function terminal_query.identity() return vim.deepcopy(identity) end

---@param on_change fun()
function terminal_query.start(on_change)
  change_listener = on_change
  local augroup_id = vim.api.nvim_create_augroup(AUGROUP_NAME, { clear = true })
  vim.api.nvim_create_autocmd('TermResponse', {
    group = augroup_id,
    callback = function(event)
      local sequence = event.data and event.data.sequence
      if
        type(sequence) == 'string'
        and terminal_query.handle_response(sequence)
        and change_listener
      then
        change_listener()
      end
    end,
  })
  if #vim.api.nvim_list_uis() > 0 then
    pcall(vim.api.nvim_ui_send, VERSION_QUERY .. PRIMARY_ATTRIBUTES_QUERY)
  end
end

function terminal_query.reset() identity = {} end

return terminal_query
