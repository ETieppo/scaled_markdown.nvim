local expect = require 'harness.assertions'
local spec = require 'harness.spec'
local table_cell_parser = require 'scaled_markdown.mods.table.table_cell_parser'

spec.describe('table_cell_parser', function()
  spec.it(
    'keeps plain text as a single segment',
    function()
      expect.deep_equal(table_cell_parser.parse 'plain text', {
        text = 'plain text',
        segments = { { text = 'plain text', is_code = false } },
      }, 'plain')
    end
  )

  spec.it(
    'splits code spans and drops their backticks',
    function()
      expect.deep_equal(table_cell_parser.parse 'run `make` now', {
        text = 'run make now',
        segments = {
          { text = 'run ', is_code = false },
          { text = 'make', is_code = true },
          { text = ' now', is_code = false },
        },
      }, 'code span')
    end
  )

  spec.it(
    'closes a code span only with a run of the same length',
    function()
      expect.deep_equal(
        table_cell_parser.parse '``a ` b``',
        { text = 'a ` b', segments = { { text = 'a ` b', is_code = true } } },
        'double backticks'
      )
    end
  )

  spec.it(
    'strips one surrounding space from code content',
    function()
      expect.deep_equal(
        table_cell_parser.parse '`` `x` ``',
        { text = '`x`', segments = { { text = '`x`', is_code = true } } },
        'stripped space'
      )
    end
  )

  spec.it(
    'keeps unmatched backticks as plain text',
    function()
      expect.deep_equal(table_cell_parser.parse 'a `b', {
        text = 'a `b',
        segments = { { text = 'a `b', is_code = false } },
      }, 'unmatched')
    end
  )

  spec.it(
    'returns no segments for an empty cell',
    function()
      expect.deep_equal(
        table_cell_parser.parse '',
        { text = '', segments = {} },
        'empty'
      )
    end
  )
end)
