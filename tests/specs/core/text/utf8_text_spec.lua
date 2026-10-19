local expect = require 'harness.assertions'
local spec = require 'harness.spec'
local utf8_text = require 'scaled_markdown.core.text.utf8_text'

spec.describe('utf8_text', function()
  spec.it(
    'splits multibyte text into characters',
    function()
      expect.deep_equal(
        utf8_text.split_characters 'aé─',
        { 'a', 'é', '─' },
        'characters'
      )
    end
  )

  spec.it('measures display width instead of bytes', function()
    expect.equal(utf8_text.display_width 'é─', 2, 'narrow multibyte')
    expect.equal(utf8_text.display_width '漢字', 4, 'wide characters')
    expect.equal(utf8_text.display_width '', 0, 'empty')
  end)

  spec.it('pads to the requested display width', function()
    expect.equal(utf8_text.pad_right('é', 3), 'é  ', 'right')
    expect.equal(utf8_text.pad_left('é', 3), '  é', 'left')
    expect.equal(utf8_text.pad_center('é', 4), ' é  ', 'center')
  end)

  spec.it('never truncates text wider than the target', function()
    expect.equal(utf8_text.pad_right('abcd', 2), 'abcd', 'right')
    expect.equal(utf8_text.pad_left('abcd', 2), 'abcd', 'left')
    expect.equal(utf8_text.pad_center('abcd', 2), 'abcd', 'center')
  end)

  spec.it(
    'trims surrounding whitespace',
    function() expect.equal(utf8_text.trim '  a b  ', 'a b', 'trimmed') end
  )
end)
