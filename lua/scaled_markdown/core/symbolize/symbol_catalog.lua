local SYMBOL_CLASS_ENUM = require 'scaled_markdown.core.enums.symbol_class_enum'
local OCTANT_CODEPOINTS_BY_MASK =
  require 'scaled_markdown.core.symbolize.octant_codepoints'
local SYMBOL_CELL_GEOMETRY =
  require 'scaled_markdown.core.symbolize.symbol_cell_geometry'
local WEDGE_SHAPES = require 'scaled_markdown.core.symbolize.wedge_shapes'
local font_binary_reader =
  require 'scaled_markdown.core.font.font_binary_reader'

local MASK_GRID_COLUMNS = 2
local SUBCELL_CENTRE_OFFSET = 0.5
local EIGHTHS_PER_CELL = 8
local LOWER_EIGHTHS_FIRST_CODEPOINT = 0x2581
local LEFT_EIGHTHS_LAST_CODEPOINT = 0x258F
local UPPER_ONE_EIGHTH_CODEPOINT = 0x2594
local RIGHT_ONE_EIGHTH_CODEPOINT = 0x2595
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

---@class symbol_catalog
local symbol_catalog = {}

---@type table<string, SymbolCandidateProps[]>
local candidates_by_specification = {}

---@param grid_columns integer
---@param grid_rows integer
---@param mask integer
---@param codepoint integer
---@return SymbolDefinitionProps
local function masked(grid_columns, grid_rows, mask, codepoint)
  return {
    codepoint = codepoint,
    covers = function(x, y)
      local bit = math.floor(
        2
          ^ (
            math.floor(y * grid_rows) * grid_columns
            + math.floor(x * grid_columns)
          )
      )
      return font_binary_reader.has_flag(mask, bit)
    end,
  }
end

---@param mask integer
---@param codepoint integer
---@return SymbolDefinitionProps
local function single_row(mask, codepoint)
  return masked(MASK_GRID_COLUMNS, 1, mask, codepoint)
end

---@param grid_rows integer
---@param codepoint_for_mask fun(mask: integer): integer
---@return SymbolDefinitionProps[]
local function build_masked_definitions(grid_rows, codepoint_for_mask)
  ---@type SymbolDefinitionProps[]
  local definitions = {}
  for mask = 0, 2 ^ (grid_rows * MASK_GRID_COLUMNS) - 1 do
    local integer_mask = math.floor(mask)
    definitions[#definitions + 1] = masked(
      MASK_GRID_COLUMNS,
      grid_rows,
      integer_mask,
      codepoint_for_mask(integer_mask)
    )
  end
  return definitions
end

---@return SymbolDefinitionProps[]
local function build_eighth_definitions()
  ---@type SymbolDefinitionProps[]
  local definitions = {}
  for eighths = 1, EIGHTHS_PER_CELL - 1 do
    local filled_fraction = eighths / EIGHTHS_PER_CELL
    definitions[#definitions + 1] = {
      codepoint = LOWER_EIGHTHS_FIRST_CODEPOINT + eighths - 1,
      covers = function(_, y) return y >= 1 - filled_fraction end,
    }
    definitions[#definitions + 1] = {
      codepoint = LEFT_EIGHTHS_LAST_CODEPOINT - eighths + 1,
      covers = function(x) return x < filled_fraction end,
    }
  end
  definitions[#definitions + 1] = {
    codepoint = UPPER_ONE_EIGHTH_CODEPOINT,
    covers = function(_, y) return y < 1 / EIGHTHS_PER_CELL end,
  }
  definitions[#definitions + 1] = {
    codepoint = RIGHT_ONE_EIGHTH_CODEPOINT,
    covers = function(x) return x >= 1 - 1 / EIGHTHS_PER_CELL end,
  }
  return definitions
end

---@param origin number[]
---@param target number[]
---@param x number
---@param y number
---@return number
local function side_of_line(origin, target, x, y)
  return (target[1] - origin[1]) * (y - origin[2])
    - (target[2] - origin[2]) * (x - origin[1])
end

---@param wedge_shape WedgeShapeProps
---@return SymbolDefinitionProps
local function wedge_definition(wedge_shape)
  local line_start, line_end = wedge_shape.line_start, wedge_shape.line_end
  local corner_side = side_of_line(
    line_start,
    line_end,
    wedge_shape.corner[1],
    wedge_shape.corner[2]
  )
  return {
    codepoint = wedge_shape.codepoint,
    covers = function(x, y)
      return side_of_line(line_start, line_end, x, y) * corner_side > 0
    end,
  }
end

---@return SymbolDefinitionProps[]
local function build_wedge_definitions()
  return vim.tbl_map(wedge_definition, WEDGE_SHAPES)
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
      masked(MASK_GRID_COLUMNS, 2, 3, UPPER_HALF_CODEPOINT),
      masked(MASK_GRID_COLUMNS, 2, 12, LOWER_HALF_CODEPOINT),
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
  [SYMBOL_CLASS_ENUM.EIGHTH] = build_eighth_definitions,
  [SYMBOL_CLASS_ENUM.WEDGE] = build_wedge_definitions,
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
  ---@type integer[]
  local filled_subcells = {}
  for subrow = 0, SYMBOL_CELL_GEOMETRY.SUBCELL_ROWS - 1 do
    local y = (subrow + SUBCELL_CENTRE_OFFSET)
      / SYMBOL_CELL_GEOMETRY.SUBCELL_ROWS
    for subcolumn = 0, SYMBOL_CELL_GEOMETRY.SUBCELL_COLUMNS - 1 do
      local x = (subcolumn + SUBCELL_CENTRE_OFFSET)
        / SYMBOL_CELL_GEOMETRY.SUBCELL_COLUMNS
      if definition.covers(x, y) then
        filled_subcells[#filled_subcells + 1] = subrow
            * SYMBOL_CELL_GEOMETRY.SUBCELL_COLUMNS
          + subcolumn
          + 1
      end
    end
  end
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
