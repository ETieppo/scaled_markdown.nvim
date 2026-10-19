local text_line_layout = require 'scaled_markdown.core.layout.text_line_layout'
local utf8_text = require 'scaled_markdown.core.text.utf8_text'

local WORD_PATTERN = '%S+'
local WORD_SEPARATOR = ' '

---@class text_word_wrapper
local text_word_wrapper = {}

---@param face FontFaceProps
---@param text string
---@return number
local function measure(face, text)
  return text_line_layout.layout(face, text).advance_width
end

---@param face FontFaceProps
---@param word string
---@param max_width number
---@return string[]
local function split_oversized_word(face, word, max_width)
  ---@type string[]
  local pieces = {}
  local current_piece = ''
  for _, character in ipairs(utf8_text.split_characters(word)) do
    local candidate = current_piece .. character
    if current_piece ~= '' and measure(face, candidate) > max_width then
      pieces[#pieces + 1] = current_piece
      current_piece = character
    else
      current_piece = candidate
    end
  end
  if current_piece ~= '' then pieces[#pieces + 1] = current_piece end
  return pieces
end

---@param face FontFaceProps
---@param text string
---@param max_width number
---@return string[]
local function collect_fitting_words(face, text, max_width)
  ---@type string[]
  local words = {}
  for word in text:gmatch(WORD_PATTERN) do
    if measure(face, word) > max_width then
      vim.list_extend(words, split_oversized_word(face, word, max_width))
    else
      words[#words + 1] = word
    end
  end
  return words
end

---@param face FontFaceProps
---@param text string
---@param max_width number
---@return string[]
function text_word_wrapper.wrap(face, text, max_width)
  ---@type string[]
  local lines = {}
  local current_line = ''
  for _, word in ipairs(collect_fitting_words(face, text, max_width)) do
    local candidate = current_line == '' and word
      or current_line .. WORD_SEPARATOR .. word
    if current_line ~= '' and measure(face, candidate) > max_width then
      lines[#lines + 1] = current_line
      current_line = word
    else
      current_line = candidate
    end
  end
  if current_line ~= '' then lines[#lines + 1] = current_line end
  return lines
end

return text_word_wrapper
