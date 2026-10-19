local RENDERER_ENUM = require 'scaled_markdown.core.enums.renderer_enum'
local environment = require 'helpers.environment'
local expect = require 'harness.assertions'
local heading_art = require 'helpers.heading_art'
local plugin_session = require 'helpers.plugin_session'
local spec = require 'harness.spec'

local WIDE_WIDTH = 200
local NARROW_WIDTH = 30
local PRIMARY_LEVEL = 1
local TERTIARY_LEVEL = 3
local SHORT_HEADING = 'Title'
local LONG_HEADING = 'Install and Configure the Plugin Today'
---@type RendererEnum[]
local FIGURE_FONT_RENDERERS = {
  RENDERER_ENUM.TOILET,
  RENDERER_ENUM.FIGLET,
}

for _, renderer in ipairs(FIGURE_FONT_RENDERERS) do
  spec.describe(('%s renderer'):format(renderer), function()
    spec.before_each(function()
      spec.skip_unless(
        environment.has_executable(renderer),
        environment.missing_reason { renderer }
      )
      plugin_session.start { renderer = renderer }
    end)

    spec.it('renders multi line art without blank edges', function()
      local art = heading_art.request(SHORT_HEADING, PRIMARY_LEVEL, WIDE_WIDTH)
      expect.truthy(art, 'art produced')
      ---@cast art -nil
      expect.at_least(#art.lines, 2, 'multi line art')
      expect.not_equal(vim.trim(art.lines[1]), '', 'no blank first line')
      expect.not_equal(
        vim.trim(art.lines[#art.lines]),
        '',
        'no blank last line'
      )
    end)

    spec.it('wraps natively inside the requested width', function()
      local wide_art =
        assert(heading_art.request(LONG_HEADING, PRIMARY_LEVEL, WIDE_WIDTH))
      local narrow_art =
        assert(heading_art.request(LONG_HEADING, PRIMARY_LEVEL, NARROW_WIDTH))
      expect.truthy(#narrow_art.lines > #wide_art.lines, 'narrow art is taller')
      for _, line in ipairs(narrow_art.lines) do
        expect.truthy(vim.fn.strdisplaywidth(line) <= NARROW_WIDTH, 'line fits')
      end
    end)

    spec.it('uses smaller fonts for deeper levels', function()
      local primary =
        assert(heading_art.request(SHORT_HEADING, PRIMARY_LEVEL, WIDE_WIDTH))
      local tertiary =
        assert(heading_art.request(SHORT_HEADING, TERTIARY_LEVEL, WIDE_WIDTH))
      expect.truthy(#primary.lines > #tertiary.lines, 'level 1 taller')
    end)
  end)
end
