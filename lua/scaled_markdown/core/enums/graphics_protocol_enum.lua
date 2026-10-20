---@alias GraphicsProtocolEnum 'auto'|'kitty_placeholder'|'none'|'sixel'

---@class GraphicsProtocolEnumProps
---@field AUTO GraphicsProtocolEnum
---@field KITTY_PLACEHOLDER GraphicsProtocolEnum
---@field SIXEL GraphicsProtocolEnum
---@field NONE GraphicsProtocolEnum

---@type GraphicsProtocolEnumProps
local GRAPHICS_PROTOCOL_ENUM = {
  AUTO = 'auto',
  KITTY_PLACEHOLDER = 'kitty_placeholder',
  SIXEL = 'sixel',
  NONE = 'none',
}

return GRAPHICS_PROTOCOL_ENUM
