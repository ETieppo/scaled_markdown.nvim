local SYMBOL_CELL_GEOMETRY =
  require 'scaled_markdown.core.symbolize.symbol_cell_geometry'
local symbol_cell_matcher =
  require 'scaled_markdown.core.symbolize.symbol_cell_matcher'

---@class symbol_art_builder
local symbol_art_builder = {}

---@param bitmap CoverageBitmapProps
---@param column integer
---@param row integer
---@param subcell_coverages number[]
local function read_cell_coverages(bitmap, column, row, subcell_coverages)
  local first_subcolumn = column * SYMBOL_CELL_GEOMETRY.SUBCELL_COLUMNS
  local first_subrow = row * SYMBOL_CELL_GEOMETRY.SUBCELL_ROWS
  local subcell_index = 1
  for subrow = 0, SYMBOL_CELL_GEOMETRY.SUBCELL_ROWS - 1 do
    local row_base = (first_subrow + subrow) * bitmap.width + first_subcolumn
    for subcolumn = 1, SYMBOL_CELL_GEOMETRY.SUBCELL_COLUMNS do
      subcell_coverages[subcell_index] = bitmap.values[row_base + subcolumn]
      subcell_index = subcell_index + 1
    end
  end
end

---@param bitmap CoverageBitmapProps
---@param grid SymbolGridProps
---@param candidates SymbolCandidateProps[]
---@return string[]
function symbol_art_builder.build(bitmap, grid, candidates)
  ---@type string[]
  local lines = {}
  ---@type number[]
  local subcell_coverages = {}
  for row = 0, grid.rows - 1 do
    ---@type string[]
    local characters = {}
    for column = 0, grid.columns - 1 do
      read_cell_coverages(bitmap, column, row, subcell_coverages)
      characters[column + 1] =
        symbol_cell_matcher.match(subcell_coverages, candidates)
    end
    lines[row + 1] = table.concat(characters)
  end
  return lines
end

return symbol_art_builder
