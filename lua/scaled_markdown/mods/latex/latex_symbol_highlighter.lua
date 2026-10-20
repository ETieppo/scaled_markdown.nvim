local LATEX_FUNCTION_SYMBOLS =
  require 'scaled_markdown.mods.latex.latex_function_symbols'
local LATEX_SYMBOL_CLASS_ENUM =
  require 'scaled_markdown.mods.latex.latex_symbol_class_enum'
local LATEX_SYMBOL_CLASSES =
  require 'scaled_markdown.mods.latex.latex_symbol_classes'
local latex_highlight = require 'scaled_markdown.mods.latex.highlight'
local utf8_text = require 'scaled_markdown.core.text.utf8_text'

local LETTER_PATTERN = '^%a$'
local WORD_SEPARATOR = ' '

---@type table<string, boolean>
local FUNCTION_WORDS = {}
for _, function_text in pairs(LATEX_FUNCTION_SYMBOLS) do
  for _, word in ipairs(vim.split(function_text, WORD_SEPARATOR)) do
    FUNCTION_WORDS[word] = true
  end
end

---@class latex_symbol_highlighter
local latex_symbol_highlighter = {}

---@param chunks [string, string][]
---@param text string
---@param highlight_group string
local function append_chunk(chunks, text, highlight_group)
  local last_chunk = chunks[#chunks]
  if last_chunk and last_chunk[2] == highlight_group then
    last_chunk[1] = last_chunk[1] .. text
    return
  end
  chunks[#chunks + 1] = { text, highlight_group }
end

---@param symbol_class LatexSymbolClassEnum?
---@return string
local function group_for_class(symbol_class)
  return symbol_class and latex_highlight.GROUPS.BY_SYMBOL_CLASS[symbol_class]
    or latex_highlight.GROUPS.MATH
end

---@param characters string[]
---@param start_index integer
---@return integer
local function find_word_end(characters, start_index)
  local end_index = start_index
  while
    characters[end_index + 1]
    and characters[end_index + 1]:match(LETTER_PATTERN)
  do
    end_index = end_index + 1
  end
  return end_index
end

---@param text string
---@return [string, string][]
function latex_symbol_highlighter.to_chunks(text)
  ---@type [string, string][]
  local chunks = {}
  local characters = utf8_text.split_characters(text)
  local index = 1
  while index <= #characters do
    local character = characters[index]
    if character:match(LETTER_PATTERN) then
      local end_index = find_word_end(characters, index)
      local word = table.concat(characters, '', index, end_index)
      append_chunk(
        chunks,
        word,
        group_for_class(
          FUNCTION_WORDS[word] and LATEX_SYMBOL_CLASS_ENUM.FUNCTION or nil
        )
      )
      index = end_index + 1
    else
      append_chunk(
        chunks,
        character,
        group_for_class(
          LATEX_SYMBOL_CLASSES[character]
            or LATEX_SYMBOL_CLASSES[vim.fn.strcharpart(character, 0, 1)]
        )
      )
      index = index + 1
    end
  end
  return chunks
end

return latex_symbol_highlighter
