local SYMBOL_CELL_GEOMETRY =
  require 'scaled_markdown.core.symbolize.symbol_cell_geometry'
local expect = require 'harness.assertions'
local spec = require 'harness.spec'
local symbol_catalog = require 'scaled_markdown.core.symbolize.symbol_catalog'
local symbol_cell_matcher =
  require 'scaled_markdown.core.symbolize.symbol_cell_matcher'

local SYMBOLS = 'octant+solid+half+quad'

---@param is_covered fun(subcolumn: integer, subrow: integer): boolean
---@return number[]
local function build_coverages(is_covered)
  ---@type number[]
  local coverages = {}
  for subrow = 0, SYMBOL_CELL_GEOMETRY.SUBCELL_ROWS - 1 do
    for subcolumn = 0, SYMBOL_CELL_GEOMETRY.SUBCELL_COLUMNS - 1 do
      coverages[#coverages + 1] = is_covered(subcolumn, subrow) and 1 or 0
    end
  end
  return coverages
end

---@param is_covered fun(subcolumn: integer, subrow: integer): boolean
---@return string
local function match(is_covered)
  return symbol_cell_matcher.match(
    build_coverages(is_covered),
    symbol_catalog.resolve(SYMBOLS)
  )
end

spec.describe('symbol_cell_matcher', function()
  spec.it('picks space and full block for empty and full cells', function()
    expect.equal(match(function() return false end), ' ', 'empty')
    expect.equal(match(function() return true end), '█', 'full')
  end)

  spec.it('picks half blocks for half covered cells', function()
    expect.equal(
      match(function(_, subrow) return subrow < 6 end),
      '▀',
      'upper half'
    )
    expect.equal(
      match(function(subcolumn) return subcolumn == 1 end),
      '▐',
      'right half'
    )
  end)

  spec.it('picks the nearest shape for partial coverage', function()
    expect.equal(
      match(function(_, subrow) return subrow >= 10 end),
      '▂',
      'lower quarter'
    )
  end)
end)
