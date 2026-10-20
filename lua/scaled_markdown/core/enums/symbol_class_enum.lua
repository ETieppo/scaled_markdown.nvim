---@alias SymbolClassEnum 'block'|'braille'|'eighth'|'half'|'hhalf'|'octant'|'quad'|'sextant'|'solid'|'space'|'vhalf'|'wedge'

---@class SymbolClassEnumProps
---@field SPACE SymbolClassEnum
---@field SOLID SymbolClassEnum
---@field HORIZONTAL_HALF SymbolClassEnum
---@field VERTICAL_HALF SymbolClassEnum
---@field HALF SymbolClassEnum
---@field QUAD SymbolClassEnum
---@field BLOCK SymbolClassEnum
---@field SEXTANT SymbolClassEnum
---@field OCTANT SymbolClassEnum
---@field BRAILLE SymbolClassEnum
---@field EIGHTH SymbolClassEnum
---@field WEDGE SymbolClassEnum

---@type SymbolClassEnumProps
local SYMBOL_CLASS_ENUM = {
  SPACE = 'space',
  SOLID = 'solid',
  HORIZONTAL_HALF = 'hhalf',
  VERTICAL_HALF = 'vhalf',
  HALF = 'half',
  QUAD = 'quad',
  BLOCK = 'block',
  SEXTANT = 'sextant',
  OCTANT = 'octant',
  BRAILLE = 'braille',
  EIGHTH = 'eighth',
  WEDGE = 'wedge',
}

return SYMBOL_CLASS_ENUM
