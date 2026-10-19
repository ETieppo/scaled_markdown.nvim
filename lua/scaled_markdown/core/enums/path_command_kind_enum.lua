---@alias PathCommandKindEnum 'cubic'|'line'|'move'|'quadratic'

---@class PathCommandKindEnumProps
---@field MOVE PathCommandKindEnum
---@field LINE PathCommandKindEnum
---@field QUADRATIC PathCommandKindEnum
---@field CUBIC PathCommandKindEnum

---@type PathCommandKindEnumProps
local PATH_COMMAND_KIND_ENUM = {
  MOVE = 'move',
  LINE = 'line',
  QUADRATIC = 'quadratic',
  CUBIC = 'cubic',
}

return PATH_COMMAND_KIND_ENUM
