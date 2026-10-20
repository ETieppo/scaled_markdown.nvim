local expect = require 'harness.assertions'
local spec = require 'harness.spec'
local terminal_query = require 'scaled_markdown.core.terminal.terminal_query'

spec.describe('terminal_query', function()
  spec.before_each(function() terminal_query.reset() end)

  spec.it('reads sixel support from primary device attributes', function()
    expect.truthy(terminal_query.handle_response '\27[?62;4;22c', 'changed')
    expect.truthy(terminal_query.identity().has_sixel, 'sixel')
    expect.truthy(terminal_query.handle_response '\27[?62;22c', 'changed again')
    expect.falsy(terminal_query.identity().has_sixel, 'no sixel')
  end)

  spec.it('does not mistake other attributes for sixel', function()
    terminal_query.handle_response '\27[?64;14;42c'
    expect.falsy(terminal_query.identity().has_sixel, 'no sixel')
  end)

  spec.it('reads the terminal name and version', function()
    terminal_query.handle_response '\27P>|kitty(0.35.2)\27\\'
    expect.deep_equal(
      terminal_query.identity(),
      { name = 'kitty', version = '0.35.2' },
      'parenthesized'
    )
    terminal_query.handle_response '\27P>|WezTerm 20240203-110809-5046fc22\27\\'
    expect.deep_equal(
      terminal_query.identity(),
      { name = 'wezterm', version = '20240203-110809-5046fc22' },
      'spaced'
    )
  end)

  spec.it('reports unchanged answers as no change', function()
    terminal_query.handle_response '\27[?62;4c'
    expect.falsy(terminal_query.handle_response '\27[?62;4c', 'same answer')
  end)

  spec.it('ignores unrelated responses', function()
    expect.falsy(
      terminal_query.handle_response '\27]11;rgb:0000/0000/0000\27\\',
      'osc'
    )
    expect.deep_equal(terminal_query.identity(), {}, 'untouched')
  end)
end)
