---@alias LatexNodeKindEnum
---| 'text'
---| 'row'
---| 'fraction'
---| 'binomial'
---| 'script'
---| 'root'
---| 'accent'
---| 'delimited'
---| 'limit_operator'
---| 'table'

---@class LatexNodeKindEnumProps
---@field TEXT LatexNodeKindEnum
---@field ROW LatexNodeKindEnum
---@field FRACTION LatexNodeKindEnum
---@field BINOMIAL LatexNodeKindEnum
---@field SCRIPT LatexNodeKindEnum
---@field ROOT LatexNodeKindEnum
---@field ACCENT LatexNodeKindEnum
---@field DELIMITED LatexNodeKindEnum
---@field LIMIT_OPERATOR LatexNodeKindEnum
---@field TABLE LatexNodeKindEnum

---@type LatexNodeKindEnumProps
local LATEX_NODE_KIND_ENUM = {
  TEXT = 'text',
  ROW = 'row',
  FRACTION = 'fraction',
  BINOMIAL = 'binomial',
  SCRIPT = 'script',
  ROOT = 'root',
  ACCENT = 'accent',
  DELIMITED = 'delimited',
  LIMIT_OPERATOR = 'limit_operator',
  TABLE = 'table',
}

return LATEX_NODE_KIND_ENUM
