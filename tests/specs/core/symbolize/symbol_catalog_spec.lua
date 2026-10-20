local expect = require 'harness.assertions'
local spec = require 'harness.spec'
local symbol_catalog = require 'scaled_markdown.core.symbolize.symbol_catalog'

local OCTANT_SHAPE_COUNT = 256
local SPACE = ' '
local FULL_BLOCK = '█'

---@param candidates SymbolCandidateProps[]
---@return string[]
local function characters(candidates)
  return vim.tbl_map(
    ---@param candidate SymbolCandidateProps
    ---@return string
    function(candidate) return candidate.character end,
    candidates
  )
end

---@param values string[]
---@return integer
local function count_distinct(values)
  ---@type table<string, boolean>
  local seen = {}
  local count = 0
  for _, value in ipairs(values) do
    if not seen[value] then
      seen[value] = true
      count = count + 1
    end
  end
  return count
end

spec.describe('symbol_catalog', function()
  spec.it('maps every octant shape to a distinct character', function()
    local octant_characters = characters(symbol_catalog.resolve 'octant')
    expect.equal(#octant_characters, OCTANT_SHAPE_COUNT, 'shape count')
    expect.equal(
      count_distinct(octant_characters),
      OCTANT_SHAPE_COUNT,
      'distinct characters'
    )
  end)

  spec.it(
    'always offers the space character first',
    function()
      expect.deep_equal(
        characters(symbol_catalog.resolve 'solid'),
        { SPACE, FULL_BLOCK },
        'solid'
      )
    end
  )

  spec.it('drops duplicated shapes across classes', function()
    local combined = symbol_catalog.resolve 'octant+solid+half+quad'
    expect.equal(
      #combined,
      OCTANT_SHAPE_COUNT,
      'octants cover the other classes'
    )
  end)

  spec.it(
    'removes classes prefixed with a minus sign',
    function()
      expect.deep_equal(
        characters(symbol_catalog.resolve 'block-quad-hhalf-vhalf'),
        { SPACE, FULL_BLOCK },
        'only solid remains'
      )
    end
  )

  spec.it(
    'ignores unknown classes',
    function()
      expect.deep_equal(
        characters(symbol_catalog.resolve 'unknown'),
        { SPACE },
        'space only'
      )
    end
  )

  spec.it('builds eighth and wedge shapes', function()
    expect.equal(#symbol_catalog.resolve 'eighth', 17, 'eighths')
    expect.equal(#symbol_catalog.resolve 'wedge', 45, 'wedges')
  end)

  spec.it('builds sextant and braille shapes', function()
    expect.equal(#symbol_catalog.resolve 'sextant', 64, 'sextants')
    expect.equal(#symbol_catalog.resolve 'braille', 256, 'braille')
  end)
end)
