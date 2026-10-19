local expect = require 'harness.assertions'
local spec = require 'harness.spec'
local symbol_grid_fitter =
  require 'scaled_markdown.core.symbolize.symbol_grid_fitter'

spec.describe('symbol_grid_fitter', function()
  spec.it(
    'keeps the requested rows when the width fits',
    function()
      expect.deep_equal(
        symbol_grid_fitter.fit(1000, 150, 7, 4000),
        { columns = 93, rows = 7 },
        'grid'
      )
    end
  )

  spec.it(
    'shrinks rows to keep the aspect ratio when the width binds',
    function()
      expect.deep_equal(
        symbol_grid_fitter.fit(1000, 150, 7, 40),
        { columns = 40, rows = 3 },
        'grid'
      )
    end
  )

  spec.it(
    'never produces an empty grid',
    function()
      expect.deep_equal(
        symbol_grid_fitter.fit(1, 1000, 1, 10),
        { columns = 1, rows = 1 },
        'grid'
      )
    end
  )
end)
