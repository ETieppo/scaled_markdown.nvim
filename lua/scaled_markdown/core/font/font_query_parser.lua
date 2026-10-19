local WEIGHT_BY_NAME = require 'scaled_markdown.core.font.font_weight_scale'

local ELEMENT_SEPARATOR_PATTERN = '[^:]+'
local PROPERTY_PATTERN = '^%s*(%w+)%s*=%s*(.-)%s*$'
local WORD_PATTERN = '%a+'
local REGULAR_WEIGHT = 400
---@type table<string, boolean>
local ITALIC_STYLE_NAMES = { italic = true, oblique = true }
local STYLE_PROPERTY = 'style'
local WEIGHT_PROPERTY = 'weight'
local SLANT_PROPERTY = 'slant'

---@class font_query_parser
local font_query_parser = {}

---@param word string
---@return string
local function normalize_word(word) return (word:lower():gsub('[%s_-]', '')) end

---@param query FontQueryProps
---@param word string
local function apply_style_word(query, word)
  local normalized_word = normalize_word(word)
  if ITALIC_STYLE_NAMES[normalized_word] then
    query.is_italic = true
  elseif WEIGHT_BY_NAME[normalized_word] then
    query.weight = WEIGHT_BY_NAME[normalized_word]
  end
end

---@param query FontQueryProps
---@param name string
---@param value string
local function apply_property(query, name, value)
  local property_name = name:lower()
  if property_name == WEIGHT_PROPERTY then
    local numeric_weight = tonumber(value)
    query.weight = numeric_weight and math.floor(numeric_weight)
      or WEIGHT_BY_NAME[normalize_word(value)]
      or query.weight
  elseif property_name == SLANT_PROPERTY then
    query.is_italic = ITALIC_STYLE_NAMES[normalize_word(value)] or false
  elseif property_name == STYLE_PROPERTY then
    for word in value:gmatch(WORD_PATTERN) do
      apply_style_word(query, word)
    end
  end
end

---@param font_query string
---@return FontQueryProps
function font_query_parser.parse(font_query)
  ---@type FontQueryProps
  local query = {
    family = '',
    weight = REGULAR_WEIGHT,
    is_italic = false,
    requested_style = nil,
  }
  local is_family = true
  for element in font_query:gmatch(ELEMENT_SEPARATOR_PATTERN) do
    if is_family then
      query.family = vim.trim(element)
      is_family = false
    else
      local name, value = element:match(PROPERTY_PATTERN)
      if name then
        apply_property(query, name, value)
      else
        query.requested_style = vim.trim(element)
        apply_style_word(query, element)
      end
    end
  end
  return query
end

---@param family string
---@return string
function font_query_parser.normalize_family(family)
  return (family:lower():gsub('[^%w]', ''))
end

return font_query_parser
