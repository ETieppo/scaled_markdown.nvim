---@alias CalloutTypeEnum 'CAUTION'|'IMPORTANT'|'NOTE'|'TIP'|'WARNING'

---@class CalloutTypeEnumProps
---@field NOTE CalloutTypeEnum
---@field TIP CalloutTypeEnum
---@field IMPORTANT CalloutTypeEnum
---@field WARNING CalloutTypeEnum
---@field CAUTION CalloutTypeEnum

---@type CalloutTypeEnumProps
local CALLOUT_TYPE_ENUM = {
  NOTE = 'NOTE',
  TIP = 'TIP',
  IMPORTANT = 'IMPORTANT',
  WARNING = 'WARNING',
  CAUTION = 'CAUTION',
}

return CALLOUT_TYPE_ENUM
