local LATEX_ARROW_SYMBOLS =
  require 'scaled_markdown.mods.latex.latex_arrow_symbols'
local LATEX_DELIMITER_PIECES =
  require 'scaled_markdown.mods.latex.latex_delimiter_pieces'
local LATEX_GREEK_SYMBOLS =
  require 'scaled_markdown.mods.latex.latex_greek_symbols'
local LATEX_MISC_SYMBOLS =
  require 'scaled_markdown.mods.latex.latex_misc_symbols'
local LATEX_OPERATOR_SYMBOLS =
  require 'scaled_markdown.mods.latex.latex_operator_symbols'
local LATEX_RELATION_SYMBOLS =
  require 'scaled_markdown.mods.latex.latex_relation_symbols'
local LATEX_SCRIPT_CHARACTERS =
  require 'scaled_markdown.mods.latex.latex_script_characters'
local LATEX_SYMBOL_CLASS_ENUM =
  require 'scaled_markdown.mods.latex.latex_symbol_class_enum'

local DIGITS = '0123456789'
local DIGIT_PATTERN = '^%d$'

---@type string[]
local LARGE_OPERATOR_CHARACTERS = {
  '∑',
  '∏',
  '∐',
  '∫',
  '∬',
  '∭',
  '∮',
  '⋃',
  '⋂',
  '⋁',
  '⋀',
  '⨁',
  '⨂',
  '⨀',
  '⨄',
  '√',
  '∛',
  '∜',
}

---@type string[]
local EXTRA_OPERATOR_CHARACTERS = { '+', '−', '-', '*', '/', '⁄' }

---@type string[]
local EXTRA_RELATION_CHARACTERS = { '=', '<', '>' }

---@type string[]
local STRUCTURE_CHARACTERS = {
  '(',
  ')',
  '[',
  ']',
  '{',
  '}',
  '|',
  '‖',
  '⟨',
  '⟩',
  '⌈',
  '⌉',
  '⌊',
  '⌋',
  '─',
  '┌',
  '│',
  '╲',
  '_',
}

---@type table<string, LatexSymbolClassEnum>
local LATEX_SYMBOL_CLASSES = {}

---@param characters string[]
---@param symbol_class LatexSymbolClassEnum
local function assign_characters(characters, symbol_class)
  for _, character in ipairs(characters) do
    LATEX_SYMBOL_CLASSES[character] = symbol_class
  end
end

---@param symbols table<string, string>
---@param symbol_class LatexSymbolClassEnum
local function assign_symbol_values(symbols, symbol_class)
  for _, symbol in pairs(symbols) do
    LATEX_SYMBOL_CLASSES[symbol] = symbol_class
  end
end

---@param script_characters table<string, string>
local function assign_script_digits(script_characters)
  for character, script_character in pairs(script_characters) do
    if character:match(DIGIT_PATTERN) then
      LATEX_SYMBOL_CLASSES[script_character] = LATEX_SYMBOL_CLASS_ENUM.NUMBER
    end
  end
end

assign_symbol_values(LATEX_MISC_SYMBOLS, LATEX_SYMBOL_CLASS_ENUM.SYMBOL)
assign_symbol_values(LATEX_GREEK_SYMBOLS, LATEX_SYMBOL_CLASS_ENUM.GREEK)
assign_symbol_values(LATEX_OPERATOR_SYMBOLS, LATEX_SYMBOL_CLASS_ENUM.OPERATOR)
assign_symbol_values(LATEX_RELATION_SYMBOLS, LATEX_SYMBOL_CLASS_ENUM.RELATION)
assign_symbol_values(LATEX_ARROW_SYMBOLS, LATEX_SYMBOL_CLASS_ENUM.RELATION)
assign_characters(EXTRA_OPERATOR_CHARACTERS, LATEX_SYMBOL_CLASS_ENUM.OPERATOR)
assign_characters(EXTRA_RELATION_CHARACTERS, LATEX_SYMBOL_CLASS_ENUM.RELATION)
assign_characters(
  LARGE_OPERATOR_CHARACTERS,
  LATEX_SYMBOL_CLASS_ENUM.LARGE_OPERATOR
)
assign_characters(STRUCTURE_CHARACTERS, LATEX_SYMBOL_CLASS_ENUM.DELIMITER)
for _, pieces in pairs(LATEX_DELIMITER_PIECES) do
  assign_characters({
    pieces.top,
    pieces.extender,
    pieces.bottom,
    pieces.middle,
    pieces.short_top,
    pieces.short_bottom,
  }, LATEX_SYMBOL_CLASS_ENUM.DELIMITER)
end
LATEX_SYMBOL_CLASSES[' '] = nil
assign_characters(vim.split(DIGITS, ''), LATEX_SYMBOL_CLASS_ENUM.NUMBER)
assign_script_digits(LATEX_SCRIPT_CHARACTERS.SUPERSCRIPT)
assign_script_digits(LATEX_SCRIPT_CHARACTERS.SUBSCRIPT)

return LATEX_SYMBOL_CLASSES
