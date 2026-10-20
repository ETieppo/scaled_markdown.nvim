local LATEX_SCRIPT_CHARACTERS =
  require 'scaled_markdown.mods.latex.latex_script_characters'
local utf8_text = require 'scaled_markdown.core.text.utf8_text'

---@class latex_script_formatter
local latex_script_formatter = {}

---@param script_characters table<string, string>
---@return table<string, string>
local function with_identity_entries(script_characters)
  ---@type table<string, string>
  local extended_characters = {}
  for _, script_character in pairs(script_characters) do
    extended_characters[script_character] = script_character
  end
  for character, script_character in pairs(script_characters) do
    extended_characters[character] = script_character
  end
  return extended_characters
end

local SUPERSCRIPT_CHARACTERS =
  with_identity_entries(LATEX_SCRIPT_CHARACTERS.SUPERSCRIPT)
local SUBSCRIPT_CHARACTERS =
  with_identity_entries(LATEX_SCRIPT_CHARACTERS.SUBSCRIPT)

---@param text string
---@param script_characters table<string, string>
---@return string?
local function map_every_character(text, script_characters)
  if text == '' then return nil end
  ---@type string[]
  local mapped_characters = {}
  for _, character in ipairs(utf8_text.split_characters(text)) do
    local mapped_character = script_characters[character]
    if not mapped_character then return nil end
    mapped_characters[#mapped_characters + 1] = mapped_character
  end
  return table.concat(mapped_characters)
end

---@param text string
---@return string?
function latex_script_formatter.to_superscript(text)
  return map_every_character(text, SUPERSCRIPT_CHARACTERS)
end

---@param text string
---@return string?
function latex_script_formatter.to_subscript(text)
  return map_every_character(text, SUBSCRIPT_CHARACTERS)
end

return latex_script_formatter
