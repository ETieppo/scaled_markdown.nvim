local LATEX_TOKEN_KIND_ENUM =
  require 'scaled_markdown.mods.latex.latex_token_kind_enum'
local utf8_text = require 'scaled_markdown.core.text.utf8_text'

local COMMAND_PREFIX = '\\'
local LETTER_PATTERN = '^%a$'
local WHITESPACE_PATTERN = '^%s$'

---@type table<string, LatexTokenKindEnum>
local SINGLE_CHARACTER_KINDS = {
  ['{'] = LATEX_TOKEN_KIND_ENUM.GROUP_OPEN,
  ['}'] = LATEX_TOKEN_KIND_ENUM.GROUP_CLOSE,
  ['^'] = LATEX_TOKEN_KIND_ENUM.SUPERSCRIPT,
  ['_'] = LATEX_TOKEN_KIND_ENUM.SUBSCRIPT,
}

---@class latex_tokenizer
local latex_tokenizer = {}

---@param character string?
---@return boolean
local function is_whitespace(character)
  return character ~= nil and character:match(WHITESPACE_PATTERN) ~= nil
end

---@param character string?
---@return boolean
local function is_letter(character)
  return character ~= nil and character:match(LETTER_PATTERN) ~= nil
end

---@param characters string[]
---@param index integer
---@return integer
local function skip_whitespace(characters, index)
  while is_whitespace(characters[index]) do
    index = index + 1
  end
  return index
end

---@param characters string[]
---@param index integer
---@param tokens LatexTokenProps[]
---@return integer
local function read_command(characters, index, tokens)
  local first_character = characters[index + 1]
  if not first_character then
    tokens[#tokens + 1] =
      { kind = LATEX_TOKEN_KIND_ENUM.CHARACTER, value = COMMAND_PREFIX }
    return index + 1
  end
  if not is_letter(first_character) then
    tokens[#tokens + 1] =
      { kind = LATEX_TOKEN_KIND_ENUM.COMMAND, value = first_character }
    return index + 2
  end
  local end_index = index + 1
  while is_letter(characters[end_index + 1]) do
    end_index = end_index + 1
  end
  tokens[#tokens + 1] = {
    kind = LATEX_TOKEN_KIND_ENUM.COMMAND,
    value = table.concat(characters, '', index + 1, end_index),
  }
  return end_index + 1
end

---@param characters string[]
---@param index integer
---@param tokens LatexTokenProps[]
---@return integer
local function read_whitespace(characters, index, tokens)
  local end_index = skip_whitespace(characters, index)
  tokens[#tokens + 1] = {
    kind = LATEX_TOKEN_KIND_ENUM.WHITESPACE,
    value = table.concat(characters, '', index, end_index - 1),
  }
  return end_index
end

---@param source string
---@return LatexTokenProps[]
function latex_tokenizer.tokenize(source)
  local characters = utf8_text.split_characters(source)
  ---@type LatexTokenProps[]
  local tokens = {}
  local index = 1
  while index <= #characters do
    local character = characters[index]
    if character == COMMAND_PREFIX then
      index = read_command(characters, index, tokens)
    elseif is_whitespace(character) then
      index = read_whitespace(characters, index, tokens)
    else
      tokens[#tokens + 1] = {
        kind = SINGLE_CHARACTER_KINDS[character]
          or LATEX_TOKEN_KIND_ENUM.CHARACTER,
        value = character,
      }
      index = index + 1
    end
  end
  return tokens
end

---@param token LatexTokenProps
---@return string
function latex_tokenizer.to_source(token)
  if token.kind == LATEX_TOKEN_KIND_ENUM.COMMAND then
    return COMMAND_PREFIX .. token.value
  end
  return token.value
end

return latex_tokenizer
