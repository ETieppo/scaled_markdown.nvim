local utf8_text = require 'scaled_markdown.core.text.utf8_text'

local UPPERCASE_FIRST_BYTE = ('A'):byte()
local UPPERCASE_LAST_BYTE = ('Z'):byte()
local LOWERCASE_FIRST_BYTE = ('a'):byte()
local LOWERCASE_LAST_BYTE = ('z'):byte()
local DIGIT_FIRST_BYTE = ('0'):byte()
local DIGIT_LAST_BYTE = ('9'):byte()

---@class latex_font_styler
local latex_font_styler = {}

---@param character string
---@param alphabet LatexFontAlphabetProps
---@return string
local function style_character(character, alphabet)
  local exception = alphabet.exceptions[character]
  if exception then return exception end
  if #character ~= 1 then return character end
  local byte = character:byte()
  if byte >= UPPERCASE_FIRST_BYTE and byte <= UPPERCASE_LAST_BYTE then
    return vim.fn.nr2char(
      alphabet.uppercase_start + byte - UPPERCASE_FIRST_BYTE
    )
  end
  if byte >= LOWERCASE_FIRST_BYTE and byte <= LOWERCASE_LAST_BYTE then
    return vim.fn.nr2char(
      alphabet.lowercase_start + byte - LOWERCASE_FIRST_BYTE
    )
  end
  if
    alphabet.digit_start
    and byte >= DIGIT_FIRST_BYTE
    and byte <= DIGIT_LAST_BYTE
  then
    return vim.fn.nr2char(alphabet.digit_start + byte - DIGIT_FIRST_BYTE)
  end
  return character
end

---@param text string
---@param alphabet LatexFontAlphabetProps
---@return string
function latex_font_styler.apply(text, alphabet)
  ---@type string[]
  local styled_characters = {}
  for _, character in ipairs(utf8_text.split_characters(text)) do
    styled_characters[#styled_characters + 1] =
      style_character(character, alphabet)
  end
  return table.concat(styled_characters)
end

return latex_font_styler
