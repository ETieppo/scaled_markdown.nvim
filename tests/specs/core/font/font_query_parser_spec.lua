local expect = require 'harness.assertions'
local font_query_parser = require 'scaled_markdown.core.font.font_query_parser'
local spec = require 'harness.spec'

spec.describe('font_query_parser', function()
  spec.it('reads the family and a style constant', function()
    local query = font_query_parser.parse 'FreeSans:bold'
    expect.equal(query.family, 'FreeSans', 'family')
    expect.equal(query.weight, 700, 'weight')
    expect.falsy(query.is_italic, 'upright')
    expect.equal(query.requested_style, 'bold', 'requested style')
  end)

  spec.it('reads fontconfig style properties', function()
    local query = font_query_parser.parse 'DejaVu Sans:style=Light Oblique'
    expect.equal(query.family, 'DejaVu Sans', 'family')
    expect.equal(query.weight, 300, 'weight')
    expect.truthy(query.is_italic, 'italic')
  end)

  spec.it('reads numeric weights and slants', function()
    local query = font_query_parser.parse 'Inter:weight=600:slant=italic'
    expect.equal(query.weight, 600, 'weight')
    expect.truthy(query.is_italic, 'italic')
  end)

  spec.it('defaults to a regular upright face', function()
    local query = font_query_parser.parse 'Noto Sans'
    expect.equal(query.weight, 400, 'weight')
    expect.falsy(query.is_italic, 'upright')
    expect.is_nil(query.requested_style, 'no requested style')
  end)

  spec.it(
    'normalizes family names for comparison',
    function()
      expect.equal(
        font_query_parser.normalize_family 'JetBrains Mono-NL',
        'jetbrainsmononl',
        'normalized'
      )
    end
  )
end)
