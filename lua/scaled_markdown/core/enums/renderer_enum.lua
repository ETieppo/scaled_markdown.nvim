---@alias RendererEnum 'figlet'|'graphics'|'plain'|'toilet'|'typeface'

---@class RendererEnumProps
---@field GRAPHICS RendererEnum
---@field TYPEFACE RendererEnum
---@field TOILET RendererEnum
---@field FIGLET RendererEnum
---@field PLAIN RendererEnum

---@type RendererEnumProps
local RENDERER_ENUM = {
  GRAPHICS = 'graphics',
  TYPEFACE = 'typeface',
  TOILET = 'toilet',
  FIGLET = 'figlet',
  PLAIN = 'plain',
}

return RENDERER_ENUM
