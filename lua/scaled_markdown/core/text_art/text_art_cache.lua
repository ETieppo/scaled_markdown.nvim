local KEY_SEPARATOR = '\31'
local LIST_VALUE_SEPARATOR = '\30'
local STYLE_ENTRY_FORMAT = '%s=%s'
local FAILED_RENDER_MARKER = false

---@class text_art_cache
local text_art_cache = {}

---@type table<string, TextArtProps|boolean>
local cached_art_by_key = {}

---@param value any
---@return string
local function serialize_value(value)
  if type(value) == 'table' then
    ---@type string[]
    local items = {}
    for index, item in ipairs(value) do
      items[index] = tostring(item)
    end
    return table.concat(items, LIST_VALUE_SEPARATOR)
  end
  return tostring(value)
end

---@param style_props TextArtStyleProps
---@return string
local function serialize_style(style_props)
  ---@type table<string, any>
  local style_fields = style_props
  local style_names = vim.tbl_keys(style_fields)
  table.sort(style_names)
  ---@type string[]
  local entries = {}
  for index, style_name in ipairs(style_names) do
    entries[index] = STYLE_ENTRY_FORMAT:format(
      style_name,
      serialize_value(style_fields[style_name])
    )
  end
  return table.concat(entries, KEY_SEPARATOR)
end

---@param renderer string
---@param style_props TextArtStyleProps
---@param width integer
---@param text string
---@return string
function text_art_cache.build_key(renderer, style_props, width, text)
  return table.concat(
    { renderer, serialize_style(style_props), tostring(width), text },
    KEY_SEPARATOR
  )
end

---@param key string
---@return TextArtProps|boolean
function text_art_cache.lookup(key) return cached_art_by_key[key] end

---@param key string
---@param art_lines? TextArtProps
function text_art_cache.store(key, art_lines)
  cached_art_by_key[key] = art_lines or FAILED_RENDER_MARKER
end

function text_art_cache.clear() cached_art_by_key = {} end

return text_art_cache
