local environment = require 'helpers.environment'
local expect = require 'harness.assertions'
local font_matcher = require 'scaled_markdown.core.font.font_matcher'
local font_query_parser = require 'scaled_markdown.core.font.font_query_parser'
local spec = require 'harness.spec'

local GENERIC_SANS_QUERY = 'sans'
local BOLD_WEIGHT = 700

spec.describe('font_matcher', function()
  spec.before_each(
    function()
      spec.skip_unless(
        environment.has_font(GENERIC_SANS_QUERY),
        environment.missing_font_reason(GENERIC_SANS_QUERY)
      )
    end
  )

  spec.it('substitutes a sans face for unknown families', function()
    local entry =
      font_matcher.match(font_query_parser.parse 'Nonexistent Family Name:bold')
    expect.truthy(entry, 'substitute found')
    ---@cast entry -nil
    expect.equal(entry.weight, BOLD_WEIGHT, 'requested weight kept')
  end)

  spec.it('honors the requested slant', function()
    local entry = font_matcher.match(font_query_parser.parse 'sans:italic')
    expect.truthy(entry, 'italic face found')
    ---@cast entry -nil
    expect.truthy(entry.is_italic, 'italic')
  end)
end)
