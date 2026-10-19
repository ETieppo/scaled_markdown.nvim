local SYMBOL_CELL_GEOMETRY =
  require 'scaled_markdown.core.symbolize.symbol_cell_geometry'

local MINIMUM_CELLS = 1

---@class symbol_grid_fitter
local symbol_grid_fitter = {}

---@param value number
---@return integer
local function round(value) return math.floor(value + 0.5) end

---@param image_width number
---@param image_height number
---@param rows integer
---@param max_columns integer
---@return SymbolGridProps
function symbol_grid_fitter.fit(image_width, image_height, rows, max_columns)
  local aspect_ratio = image_width / image_height
  local columns = math.max(
    MINIMUM_CELLS,
    round(aspect_ratio * rows / SYMBOL_CELL_GEOMETRY.CELL_WIDTH_TO_HEIGHT_RATIO)
  )
  if columns <= max_columns then return { columns = columns, rows = rows } end
  return {
    columns = max_columns,
    rows = math.max(
      MINIMUM_CELLS,
      round(
        max_columns
          * SYMBOL_CELL_GEOMETRY.CELL_WIDTH_TO_HEIGHT_RATIO
          / aspect_ratio
      )
    ),
  }
end

return symbol_grid_fitter
