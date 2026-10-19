---@alias TableRowKindEnum 'body'|'delimiter'|'header'

---@class TableRowKindEnumProps
---@field HEADER TableRowKindEnum
---@field DELIMITER TableRowKindEnum
---@field BODY TableRowKindEnum

---@type TableRowKindEnumProps
local TABLE_ROW_KIND_ENUM = {
  HEADER = 'header',
  DELIMITER = 'delimiter',
  BODY = 'body',
}

return TABLE_ROW_KIND_ENUM
