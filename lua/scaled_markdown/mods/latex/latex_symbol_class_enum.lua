---@alias LatexSymbolClassEnum
---| 'number'
---| 'operator'
---| 'relation'
---| 'greek'
---| 'symbol'
---| 'large_operator'
---| 'function'
---| 'delimiter'

---@class LatexSymbolClassEnumProps
---@field NUMBER LatexSymbolClassEnum
---@field OPERATOR LatexSymbolClassEnum
---@field RELATION LatexSymbolClassEnum
---@field GREEK LatexSymbolClassEnum
---@field SYMBOL LatexSymbolClassEnum
---@field LARGE_OPERATOR LatexSymbolClassEnum
---@field FUNCTION LatexSymbolClassEnum
---@field DELIMITER LatexSymbolClassEnum

---@type LatexSymbolClassEnumProps
local LATEX_SYMBOL_CLASS_ENUM = {
  NUMBER = 'number',
  OPERATOR = 'operator',
  RELATION = 'relation',
  GREEK = 'greek',
  SYMBOL = 'symbol',
  LARGE_OPERATOR = 'large_operator',
  FUNCTION = 'function',
  DELIMITER = 'delimiter',
}

return LATEX_SYMBOL_CLASS_ENUM
