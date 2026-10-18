



local KEY_SEPARATOR = '\31'
local LIST_VALUE_SEPARATOR = '\30'
local STYLE_ENTRY_FORMAT = '%s=%s'
local FAILED_RENDER_MARKER = false

local text_art_cache = {}


local cached_art_by_key = {}

local function serialize_value(value)
   if type(value) == "table" then
      local items = {}
      for index, item in ipairs(value) do
         items[index] = tostring(item)
      end
      return table.concat(items, LIST_VALUE_SEPARATOR)
   end
   return tostring(value)
end

local function serialize_style(style_props)
   local style_fields = style_props
   local style_names = vim.tbl_keys(style_fields)
   table.sort(style_names)
   local entries = {}
   for index, style_name in ipairs(style_names) do
      entries[index] = STYLE_ENTRY_FORMAT:format(
      style_name,
      serialize_value(style_fields[style_name]))

   end
   return table.concat(entries, KEY_SEPARATOR)
end

function text_art_cache.build_key(
   renderer,
   style_props,
   width,
   text)

   return table.concat(
   { renderer, serialize_style(style_props), tostring(width), text },
   KEY_SEPARATOR)

end

function text_art_cache.lookup(
   key)
   return cached_art_by_key[key] end

function text_art_cache.store(key, art_lines)
   cached_art_by_key[key] = art_lines or FAILED_RENDER_MARKER
end

function text_art_cache.clear() cached_art_by_key = {} end

return text_art_cache
