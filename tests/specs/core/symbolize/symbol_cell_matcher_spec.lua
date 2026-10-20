local SYMBOL_CELL_GEOMETRY =
  require 'scaled_markdown.core.symbolize.symbol_cell_geometry'
local expect = require 'harness.assertions'
local spec = require 'harness.spec'
local symbol_catalog = require 'scaled_markdown.core.symbolize.symbol_catalog'
local symbol_cell_matcher =
  require 'scaled_markdown.core.symbolize.symbol_cell_matcher'

local SYMBOLS = 'octant+solid+half+quad'

---@param is_covered fun(x: number, y: number): boolean
---@return number[]
local function build_coverages(is_covered)
  ---@type number[]
  local coverages = {}
  for subrow = 0, SYMBOL_CELL_GEOMETRY.SUBCELL_ROWS - 1 do
    for subcolumn = 0, SYMBOL_CELL_GEOMETRY.SUBCELL_COLUMNS - 1 do
      coverages[#coverages + 1] = is_covered(
        (subcolumn + 0.5) / SYMBOL_CELL_GEOMETRY.SUBCELL_COLUMNS,
        (subrow + 0.5) / SYMBOL_CELL_GEOMETRY.SUBCELL_ROWS
      ) and 1 or 0
    end
  end
  return coverages
end

---@param is_covered fun(x: number, y: number): boolean
---@param symbols? string
---@return string
local function match(is_covered, symbols)
  return symbol_cell_matcher.match(
    build_coverages(is_covered),
    symbol_catalog.resolve(symbols or SYMBOLS)
  )
end

spec.describe('symbol_cell_matcher', function()
  spec.it('picks space and full block for empty and full cells', function()
    expect.equal(match(function() return false end), ' ', 'empty')
    expect.equal(match(function() return true end), '█', 'full')
  end)

  spec.it('picks half blocks for half covered cells', function()
    expect.equal(match(function(_, y) return y < 0.5 end), '▀', 'upper half')
    expect.equal(match(function(x) return x >= 0.5 end), '▐', 'right half')
  end)

  spec.it('picks the nearest shape for partial coverage', function()
    expect.equal(
      match(function(_, y) return y >= 0.75 end),
      '▂',
      'lower quarter'
    )
  end)

  spec.it('picks eighth blocks for thin strokes', function()
    expect.equal(
      match(function(x) return x < 3 / 8 end, 'eighth+solid'),
      '▍',
      'left three eighths'
    )
    expect.equal(
      match(function(_, y) return y >= 7 / 8 end, 'eighth+solid'),
      '▁',
      'lower one eighth'
    )
  end)

  spec.it('picks wedges for diagonal edges', function()
    expect.equal(
      match(function(x, y) return x > (1 - y) / 2 end, 'wedge+solid'),
      '🭅',
      'steep lower right diagonal'
    )
    expect.equal(
      match(function(x, y) return y >= 2 / 3 - x / 3 end, 'wedge+solid'),
      '🭆',
      'shallow lower right diagonal'
    )
  end)
end)
