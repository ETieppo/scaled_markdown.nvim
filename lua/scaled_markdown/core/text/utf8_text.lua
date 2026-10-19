local CHARACTER_SPLIT_PATTERN = '\\zs'

---@class utf8_text
local utf8_text = {}

---@param text string
---@return string[]
function utf8_text.split_characters(text)
  return vim.fn.split(text, CHARACTER_SPLIT_PATTERN)
end

---@param text string
---@return integer[]
function utf8_text.codepoints(text)
  ---@type integer[]
  local codepoints = {}
  for _, character in ipairs(utf8_text.split_characters(text)) do
    codepoints[#codepoints + 1] = vim.fn.char2nr(character)
  end
  return codepoints
end

---@param text string
---@return integer
function utf8_text.display_width(text) return vim.fn.strdisplaywidth(text) end

---@param text string
---@param width integer
---@return string
function utf8_text.pad_right(text, width)
  return text
    .. string.rep(' ', math.max(0, width - utf8_text.display_width(text)))
end

---@param text string
---@param width integer
---@return string
function utf8_text.pad_left(text, width)
  return string.rep(' ', math.max(0, width - utf8_text.display_width(text)))
    .. text
end

---@param text string
---@param width integer
---@return string
function utf8_text.pad_center(text, width)
  local free_width = math.max(0, width - utf8_text.display_width(text))
  local left_width = math.floor(free_width / 2)
  return string.rep(' ', left_width)
    .. text
    .. string.rep(' ', free_width - left_width)
end

---@param text string
---@return string
function utf8_text.trim(text) return vim.trim(text) end

return utf8_text
