local font_resolver = require 'scaled_markdown.core.text_art.font_resolver'

local MISSING_REASON_FORMAT = 'requires executables: %s'
local MISSING_FONT_REASON_FORMAT = 'requires font: %s'
local NAME_SEPARATOR = ', '

---@class environment
local environment = {}

---@param name string
---@return boolean
function environment.has_executable(name) return vim.fn.executable(name) == 1 end

---@param names string[]
---@return boolean
function environment.has_executables(names)
  for _, name in ipairs(names) do
    if not environment.has_executable(name) then return false end
  end
  return true
end

---@param names string[]
---@return string
function environment.missing_reason(names)
  return MISSING_REASON_FORMAT:format(table.concat(names, NAME_SEPARATOR))
end

---@param font_query string
---@return boolean
function environment.has_font(font_query)
  return font_resolver.resolve(font_query) ~= nil
end

---@param font_query string
---@return string
function environment.missing_font_reason(font_query)
  return MISSING_FONT_REASON_FORMAT:format(font_query)
end

return environment
