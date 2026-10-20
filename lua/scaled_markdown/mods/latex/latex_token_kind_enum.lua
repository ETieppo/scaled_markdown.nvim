---@alias LatexTokenKindEnum
---| 'command'
---| 'character'
---| 'whitespace'
---| 'group_open'
---| 'group_close'
---| 'superscript'
---| 'subscript'

---@class LatexTokenKindEnumProps
---@field COMMAND LatexTokenKindEnum
---@field CHARACTER LatexTokenKindEnum
---@field WHITESPACE LatexTokenKindEnum
---@field GROUP_OPEN LatexTokenKindEnum
---@field GROUP_CLOSE LatexTokenKindEnum
---@field SUPERSCRIPT LatexTokenKindEnum
---@field SUBSCRIPT LatexTokenKindEnum

---@type LatexTokenKindEnumProps
local LATEX_TOKEN_KIND_ENUM = {
  COMMAND = 'command',
  CHARACTER = 'character',
  WHITESPACE = 'whitespace',
  GROUP_OPEN = 'group_open',
  GROUP_CLOSE = 'group_close',
  SUPERSCRIPT = 'superscript',
  SUBSCRIPT = 'subscript',
}

return LATEX_TOKEN_KIND_ENUM
