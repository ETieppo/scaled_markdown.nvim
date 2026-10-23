---@alias CalloutTypeEnum
---| 'NOTE'
---| 'TIP'
---| 'IMPORTANT'
---| 'WARNING'
---| 'WARN'
---| 'CAUTION'
---| 'ABSTRACT'
---| 'SUMMARY'
---| 'TLDR'
---| 'INFO'
---| 'TODO'
---| 'HINT'
---| 'SUCCESS'
---| 'CHECK'
---| 'DONE'
---| 'QUESTION'
---| 'HELP'
---| 'FAQ'
---| 'ATTENTION'
---| 'FAILURE'
---| 'FAIL'
---| 'MISSING'
---| 'DANGER'
---| 'ERROR'
---| 'BUG'
---| 'EXAMPLE'
---| 'QUOTE'
---| 'CITE'

---@class CalloutTypeEnumProps
---@field NOTE CalloutTypeEnum
---@field TIP CalloutTypeEnum
---@field IMPORTANT CalloutTypeEnum
---@field WARNING CalloutTypeEnum
---@field WARN CalloutTypeEnum
---@field CAUTION CalloutTypeEnum
---@field ABSTRACT CalloutTypeEnum
---@field SUMMARY CalloutTypeEnum
---@field TLDR CalloutTypeEnum
---@field INFO CalloutTypeEnum
---@field TODO CalloutTypeEnum
---@field HINT CalloutTypeEnum
---@field SUCCESS CalloutTypeEnum
---@field CHECK CalloutTypeEnum
---@field DONE CalloutTypeEnum
---@field QUESTION CalloutTypeEnum
---@field HELP CalloutTypeEnum
---@field FAQ CalloutTypeEnum
---@field ATTENTION CalloutTypeEnum
---@field FAILURE CalloutTypeEnum
---@field FAIL CalloutTypeEnum
---@field MISSING CalloutTypeEnum
---@field DANGER CalloutTypeEnum
---@field ERROR CalloutTypeEnum
---@field BUG CalloutTypeEnum
---@field EXAMPLE CalloutTypeEnum
---@field QUOTE CalloutTypeEnum
---@field CITE CalloutTypeEnum

---@type CalloutTypeEnumProps
local CALLOUT_TYPE_ENUM = {
  NOTE = 'NOTE',
  TIP = 'TIP',
  IMPORTANT = 'IMPORTANT',
  WARNING = 'WARNING',
  WARN = 'WARN',
  CAUTION = 'CAUTION',
  ABSTRACT = 'ABSTRACT',
  SUMMARY = 'SUMMARY',
  TLDR = 'TLDR',
  INFO = 'INFO',
  TODO = 'TODO',
  HINT = 'HINT',
  SUCCESS = 'SUCCESS',
  CHECK = 'CHECK',
  DONE = 'DONE',
  QUESTION = 'QUESTION',
  HELP = 'HELP',
  FAQ = 'FAQ',
  ATTENTION = 'ATTENTION',
  FAILURE = 'FAILURE',
  FAIL = 'FAIL',
  MISSING = 'MISSING',
  DANGER = 'DANGER',
  ERROR = 'ERROR',
  BUG = 'BUG',
  EXAMPLE = 'EXAMPLE',
  QUOTE = 'QUOTE',
  CITE = 'CITE',
}

return CALLOUT_TYPE_ENUM
