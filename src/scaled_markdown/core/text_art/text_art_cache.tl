local type TextArtProps = require 'scaled_markdown.core.types.text_art_props'
local type TextArtStyleProps =
  require 'scaled_markdown.core.types.text_art_style_props'

local KEY_SEPARATOR <const> = '\31'
local LIST_VALUE_SEPARATOR <const> = '\30'
local STYLE_ENTRY_FORMAT <const> = '%s=%s'
local FAILED_RENDER_MARKER <const> = false

local record text_art_cache
end

local cached_art_by_key: {string: TextArtProps | boolean} = {}

local function serialize_value(value: any): string
  if value is {any} then
    local items: {string} = {}
    for index, item in ipairs(value) do
      items[index] = tostring(item)
    end
    return table.concat(items, LIST_VALUE_SEPARATOR)
  end
  return tostring(value)
end

local function serialize_style(style_props: TextArtStyleProps): string
  local style_fields = style_props as {string: any}
  local style_names = vim.tbl_keys(style_fields)
  table.sort(style_names)
  local entries: {string} = {}
  for index, style_name in ipairs(style_names) do
    entries[index] = STYLE_ENTRY_FORMAT:format(
      style_name,
      serialize_value(style_fields[style_name])
    )
  end
  return table.concat(entries, KEY_SEPARATOR)
end

function text_art_cache.build_key(
  renderer: string,
  style_props: TextArtStyleProps,
  width: integer,
  text: string
): string
  return table.concat(
    { renderer, serialize_style(style_props), tostring(width), text },
    KEY_SEPARATOR
  )
end

function text_art_cache.lookup(
  key: string
): TextArtProps | boolean return cached_art_by_key[key] end

function text_art_cache.store(key: string, art_lines: TextArtProps)
  cached_art_by_key[key] = art_lines or FAILED_RENDER_MARKER
end

function text_art_cache.clear() cached_art_by_key = {} end

return text_art_cache
