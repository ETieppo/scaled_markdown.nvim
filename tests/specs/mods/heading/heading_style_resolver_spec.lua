local RENDERER_ENUM = require 'scaled_markdown.core.enums.renderer_enum'
local expect = require 'harness.assertions'
local gradient_palette =
  require 'scaled_markdown.core.highlight.gradient_palette'
local heading_style_resolver =
  require 'scaled_markdown.mods.heading.heading_style_resolver'
local plugin_session = require 'helpers.plugin_session'
local spec = require 'harness.spec'

local UNCONFIGURED_LEVEL = 3
---@type table<RendererEnum, StyleProps>
local STYLES = {
  [RENDERER_ENUM.GRAPHICS] = {
    font = 'Sans:bold',
    line_height_cells_by_level = { 3, 2 },
  },
  [RENDERER_ENUM.TYPEFACE] = {
    font = 'Sans:bold',
    symbols = 'block',
    rows_by_level = { 7, 5 },
  },
  [RENDERER_ENUM.TOILET] = { fonts_by_level = { 'mono12', 'mono9' } },
  [RENDERER_ENUM.FIGLET] = { fonts_by_level = { 'big', 'standard' } },
}

spec.describe('heading_style_resolver', function()
  spec.before_each(function() plugin_session.start() end)

  spec.it('resolves a style per renderer for a configured level', function()
    local styles = heading_style_resolver.resolve(STYLES, 1)
    expect.deep_equal(
      styles[RENDERER_ENUM.TYPEFACE],
      { font = 'Sans:bold', symbols = 'block', rows = 7 },
      'typeface'
    )
    expect.deep_equal(
      styles[RENDERER_ENUM.TOILET],
      { font = 'mono12' },
      'toilet'
    )
    expect.deep_equal(styles[RENDERER_ENUM.FIGLET], { font = 'big' }, 'figlet')
    expect.deep_equal(styles[RENDERER_ENUM.GRAPHICS], {
      font = 'Sans:bold',
      line_height_cells = 3,
      start_color = gradient_palette.color_at(0),
      end_color = gradient_palette.color_at(1),
    }, 'graphics')
  end)

  spec.it('uses the per level values', function()
    local styles = heading_style_resolver.resolve(STYLES, 2)
    expect.equal(styles[RENDERER_ENUM.TYPEFACE].rows, 5, 'typeface rows')
    expect.equal(styles[RENDERER_ENUM.TOILET].font, 'mono9', 'toilet font')
    expect.equal(
      styles[RENDERER_ENUM.GRAPHICS].line_height_cells,
      2,
      'graphics height'
    )
  end)

  spec.it(
    'resolves no style for levels without configuration',
    function()
      expect.deep_equal(
        heading_style_resolver.resolve(STYLES, UNCONFIGURED_LEVEL),
        {},
        'no styles'
      )
    end
  )

  spec.it('skips renderers missing from the config', function()
    local styles = heading_style_resolver.resolve(
      { [RENDERER_ENUM.TOILET] = STYLES[RENDERER_ENUM.TOILET] },
      1
    )
    expect.deep_equal(vim.tbl_keys(styles), { RENDERER_ENUM.TOILET }, 'toilet')
  end)

  spec.it('produces only scalar fields so cache keys stay stable', function()
    for _, style in pairs(heading_style_resolver.resolve(STYLES, 1)) do
      for field_name, value in pairs(style) do
        expect.not_equal(type(value), 'table', field_name .. ' is scalar')
      end
    end
  end)
end)
