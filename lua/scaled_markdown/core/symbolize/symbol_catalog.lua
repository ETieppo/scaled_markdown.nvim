local SYMBOL_CLASS_ENUM = require 'scaled_markdown.core.enums.symbol_class_enum'
local OCTANT_CODEPOINTS_BY_MASK =
  require 'scaled_markdown.core.symbolize.octant_codepoints'
local SYMBOL_CELL_GEOMETRY =
  require 'scaled_markdown.core.symbolize.symbol_cell_geometry'
local font_binary_reader =
  require 'scaled_markdown.core.font.font_binary_reader'

local SPACE_CODEPOINT = 0x20
local FULL_BLOCK_CODEPOINT = 0x2588
local UPPER_HALF_CODEPOINT = 0x2580
local LOWER_HALF_CODEPOINT = 0x2584
local LEFT_HALF_CODEPOINT = 0x258C
local RIGHT_HALF_CODEPOINT = 0x2590
---@type integer[]
local QUADRANT_CODEPOINTS_BY_MASK = {
  0x0020,
  0x2598,
  0x259D,
  0x2580,
  0x2596,
  0x258C,
  0x259E,
  0x259B,
  0x2597,
  0x259A,
  0x2590,
  0x259C,
  0x2584,
  0x2599,
  0x259F,
  0x2588,
}
local SEXTANT_FIRST_CODEPOINT = 0x1FB00
local SEXTANT_LEFT_HALF_MASK = 21
local SEXTANT_RIGHT_HALF_MASK = 42
local SEXTANT_FULL_MASK = 63
---@type table<integer, integer>
local SEXTANT_EXISTING_CODEPOINTS = {
  [0] = SPACE_CODEPOINT,
  [SEXTANT_LEFT_HALF_MASK] = LEFT_HALF_CODEPOINT,
  [SEXTANT_RIGHT_HALF_MASK] = RIGHT_HALF_CODEPOINT,
  [SEXTANT_FULL_MASK] = FULL_BLOCK_CODEPOINT,
}
local BRAILLE_FIRST_CODEPOINT = 0x2800
---@type integer[]
local BRAILLE_DOT_BITS_BY_CELL = { 1, 8, 2, 16, 4, 32, 64, 128 }
local CLASS_SEPARATOR_PATTERN = '([+-]?)([%w]+)'
local REMOVE_SIGN = '-'

---@class SymbolDefinitionProps
---@field grid_rows integer
---@field mask integer
---@field codepoint integer

---@class symbol_catalog
local symbol_catalog = {}

---@type table<string, SymbolCandidateProps[]>
local candidates_by_specification = {}

---@param mask integer
---@param codepoint integer
---@return SymbolDefinitionProps
local function single_row(mask, codepoint)
  return { grid_rows = 1, mask = mask, codepoint = codepoint }
end

---@param grid_rows integer
---@param codepoint_for_mask fun(mask: integer): integer
---@return SymbolDefinitionProps[]
local function build_masked_definitions(grid_rows, codepoint_for_mask)
  ---@type SymbolDefinitionProps[]
  local definitions = {}
  for mask = 0, 2 ^ (grid_rows * SYMBOL_CELL_GEOMETRY.SUBCELL_COLUMNS) - 1 do
    definitions[#definitions + 1] = {
      grid_rows = grid_rows,
      mask = math.floor(mask),
      codepoint = codepoint_for_mask(math.floor(mask)),
    }
  end
  return definitions
end

---@param mask integer
---@return integer
local function sextant_codepoint(mask)
  if SEXTANT_EXISTING_CODEPOINTS[mask] then
    return SEXTANT_EXISTING_CODEPOINTS[mask]
  end
  local skipped_count = (mask > SEXTANT_LEFT_HALF_MASK and 1 or 0)
    + (mask > SEXTANT_RIGHT_HALF_MASK and 1 or 0)
  return SEXTANT_FIRST_CODEPOINT + mask - 1 - skipped_count
end

---@param mask integer
---@return integer
local function braille_codepoint(mask)
  local dot_bits = 0
  for cell_index, dot_bit in ipairs(BRAILLE_DOT_BITS_BY_CELL) do
    if font_binary_reader.has_flag(mask, math.floor(2 ^ (cell_index - 1))) then
      dot_bits = dot_bits + dot_bit
    end
  end
  return BRAILLE_FIRST_CODEPOINT + dot_bits
end

---@type table<SymbolClassEnum, fun(): SymbolDefinitionProps[]>
local DEFINITION_BUILDERS = {
  [SYMBOL_CLASS_ENUM.SPACE] = function()
    return { single_row(0, SPACE_CODEPOINT) }
  end,
  [SYMBOL_CLASS_ENUM.SOLID] = function()
    return { single_row(3, FULL_BLOCK_CODEPOINT) }
  end,
  [SYMBOL_CLASS_ENUM.HORIZONTAL_HALF] = function()
    return {
      { grid_rows = 2, mask = 3, codepoint = UPPER_HALF_CODEPOINT },
      { grid_rows = 2, mask = 12, codepoint = LOWER_HALF_CODEPOINT },
    }
  end,
  [SYMBOL_CLASS_ENUM.VERTICAL_HALF] = function()
    return {
      single_row(1, LEFT_HALF_CODEPOINT),
      single_row(2, RIGHT_HALF_CODEPOINT),
    }
  end,
  [SYMBOL_CLASS_ENUM.QUAD] = function()
    return build_masked_definitions(
      2,
      ---@param mask integer
      ---@return integer
      function(mask) return QUADRANT_CODEPOINTS_BY_MASK[mask + 1] end
    )
  end,
  [SYMBOL_CLASS_ENUM.SEXTANT] = function()
    return build_masked_definitions(3, sextant_codepoint)
  end,
  [SYMBOL_CLASS_ENUM.OCTANT] = function()
    return build_masked_definitions(
      4,
      ---@param mask integer
      ---@return integer
      function(mask) return OCTANT_CODEPOINTS_BY_MASK[mask + 1] end
    )
  end,
  [SYMBOL_CLASS_ENUM.BRAILLE] = function()
    return build_masked_definitions(4, braille_codepoint)
  end,
}
---@type table<SymbolClassEnum, SymbolClassEnum[]>
local CLASS_EXPANSIONS = {
  [SYMBOL_CLASS_ENUM.HALF] = {
    SYMBOL_CLASS_ENUM.HORIZONTAL_HALF,
    SYMBOL_CLASS_ENUM.VERTICAL_HALF,
  },
  [SYMBOL_CLASS_ENUM.BLOCK] = {
    SYMBOL_CLASS_ENUM.SOLID,
    SYMBOL_CLASS_ENUM.HORIZONTAL_HALF,
    SYMBOL_CLASS_ENUM.VERTICAL_HALF,
    SYMBOL_CLASS_ENUM.QUAD,
  },
}

---@param class_name string
---@return SymbolClassEnum[]
local function expand_class(class_name)
  ---@type SymbolClassEnum
  local symbol_class = class_name
  if CLASS_EXPANSIONS[symbol_class] then
    return CLASS_EXPANSIONS[symbol_class]
  end
  if DEFINITION_BUILDERS[symbol_class] then return { symbol_class } end
  return {}
end

---@param specification string
---@return SymbolClassEnum[]
local function parse_classes(specification)
  ---@type table<SymbolClassEnum, boolean>
  local enabled_classes = { [SYMBOL_CLASS_ENUM.SPACE] = true }
  ---@type SymbolClassEnum[]
  local ordered_classes = { SYMBOL_CLASS_ENUM.SPACE }
  for sign, class_name in
    (specification or ''):lower():gmatch(CLASS_SEPARATOR_PATTERN)
  do
    for _, symbol_class in ipairs(expand_class(class_name)) do
      if sign == REMOVE_SIGN then
        enabled_classes[symbol_class] = false
      elseif enabled_classes[symbol_class] == nil then
        enabled_classes[symbol_class] = true
        ordered_classes[#ordered_classes + 1] = symbol_class
      end
    end
  end
  return vim.tbl_filter(
    ---@param symbol_class SymbolClassEnum
    ---@return boolean
    function(symbol_class) return enabled_classes[symbol_class] end,
    ordered_classes
  )
end

---@param definition SymbolDefinitionProps
---@return integer[]
local function expand_subcells(definition)
  local subrows_per_grid_row =
    math.floor(SYMBOL_CELL_GEOMETRY.SUBCELL_ROWS / definition.grid_rows)
  ---@type integer[]
  local filled_subcells = {}
  for grid_row = 0, definition.grid_rows - 1 do
    for grid_column = 0, SYMBOL_CELL_GEOMETRY.SUBCELL_COLUMNS - 1 do
      local bit = math.floor(
        2 ^ (grid_row * SYMBOL_CELL_GEOMETRY.SUBCELL_COLUMNS + grid_column)
      )
      if font_binary_reader.has_flag(definition.mask, bit) then
        for subrow_offset = 0, subrows_per_grid_row - 1 do
          local subrow = grid_row * subrows_per_grid_row + subrow_offset
          filled_subcells[#filled_subcells + 1] = subrow
              * SYMBOL_CELL_GEOMETRY.SUBCELL_COLUMNS
            + grid_column
            + 1
        end
      end
    end
  end
  table.sort(filled_subcells)
  return filled_subcells
end

---@param specification string
---@return SymbolCandidateProps[]
local function build_candidates(specification)
  ---@type SymbolCandidateProps[]
  local candidates = {}
  ---@type table<string, boolean>
  local seen_shapes = {}
  for _, symbol_class in ipairs(parse_classes(specification)) do
    for _, definition in ipairs(DEFINITION_BUILDERS[symbol_class]()) do
      local filled_subcells = expand_subcells(definition)
      local shape_key = table.concat(filled_subcells, ',')
      if not seen_shapes[shape_key] then
        seen_shapes[shape_key] = true
        candidates[#candidates + 1] = {
          character = vim.fn.nr2char(definition.codepoint),
          filled_subcells = filled_subcells,
        }
      end
    end
  end
  return candidates
end

---@param specification string
---@return SymbolCandidateProps[]
function symbol_catalog.resolve(specification)
  local key = specification or ''
  if not candidates_by_specification[key] then
    candidates_by_specification[key] = build_candidates(specification)
  end
  return candidates_by_specification[key]
end

return symbol_catalog
