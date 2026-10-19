local CORE_CONSTANTS = require 'scaled_markdown.core.constants'
local font_directories = require 'scaled_markdown.core.font.font_directories'
local font_matcher = require 'scaled_markdown.core.font.font_matcher'
local font_query_parser = require 'scaled_markdown.core.font.font_query_parser'

local DEFAULT_FACE_INDEX = 0
local UNRESOLVED_FONT_MARKER = false

---@class font_resolver
local font_resolver = {}

---@type table<string, FontFileProps|boolean>
local resolved_file_by_query = {}
---@type boolean?
local has_font_directories = nil

---@param message string
local function notify(message)
  vim.notify(
    ('[%s] %s'):format(CORE_CONSTANTS.PLUGIN_NAME, message),
    vim.log.levels.WARN
  )
end

---@param font_query string
---@param resolved_style string
local function warn_style_mismatch(font_query, resolved_style)
  notify(
    ("font '%s' resolved to style '%s'"):format(font_query, resolved_style)
  )
end

---@param font_query string
---@return FontFileProps?
local function match_font(font_query)
  if vim.uv.fs_stat(font_query) then
    return { path = font_query, face_index = DEFAULT_FACE_INDEX }
  end
  local query = font_query_parser.parse(font_query)
  local entry = font_matcher.match(query)
  if not entry then
    notify(("no font found for '%s'"):format(font_query))
    return nil
  end
  if
    query.requested_style
    and not entry.style_name
      :lower()
      :find(query.requested_style:lower(), 1, true)
  then
    warn_style_mismatch(font_query, entry.style_name)
  end
  return { path = entry.path, face_index = entry.face_index }
end

---@param font_query string
---@return FontFileProps?
function font_resolver.resolve(font_query)
  if resolved_file_by_query[font_query] == nil then
    resolved_file_by_query[font_query] = match_font(font_query)
      or UNRESOLVED_FONT_MARKER
  end
  local resolved_file = resolved_file_by_query[font_query]
  return type(resolved_file) == 'table' and resolved_file or nil
end

---@return boolean
function font_resolver.is_available()
  if has_font_directories == nil then
    has_font_directories = #font_directories.list() > 0
  end
  return has_font_directories
end

return font_resolver
