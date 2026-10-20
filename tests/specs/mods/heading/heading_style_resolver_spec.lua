local RENDERER_ENUM = require 'scaled_markdown.core.enums.renderer_enum'
local expect = require 'harness.assertions'
local gradient_palette =
  require 'scaled_markdown.core.highlight.gradient_palette'
local heading_style_resolver =
  require 'scaled_markdown.mods.heading.heading_style_resolver'
local plugin_session = require 'helpers.plugin_session'
local spec = require 'harness.spec'

local UNCONFIGURED_LEVEL = 3
---@type string[]
local METALLIC_COLORS =
  { '#6e4a0e', '#b8862b', '#f6dc8a', '#fff6d0', '#d4a13c' }
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
      gradient_colors = gradient_palette.colors(),
    }, 'graphics')
  end)

  spec.it('picks font drawn symbols in macOS Terminal by default', function()
    local saved_term_program = vim.env.TERM_PROGRAM
    ---@type table<RendererEnum, StyleProps>
    local styles_without_symbols = vim.deepcopy(STYLES)
    styles_without_symbols[RENDERER_ENUM.TYPEFACE].symbols = nil
    vim.env.TERM_PROGRAM = 'Apple_Terminal'
    local apple_symbols = heading_style_resolver.resolve(
      styles_without_symbols,
      1
    )[RENDERER_ENUM.TYPEFACE].symbols
    vim.env.TERM_PROGRAM = 'foot'
    local foot_symbols = heading_style_resolver.resolve(
      styles_without_symbols,
      1
    )[RENDERER_ENUM.TYPEFACE].symbols
    vim.env.TERM_PROGRAM = saved_term_program
    expect.equal(apple_symbols, 'solid+half+quad+eighth', 'apple terminal')
    expect.equal(foot_symbols, 'octant+solid+half+quad+eighth', 'foot')
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

  spec.it('passes every gradient stop to the graphics style', function()
    plugin_session.start { gradient = { colors = METALLIC_COLORS } }
    expect.deep_equal(
      heading_style_resolver.resolve(STYLES, 1)[RENDERER_ENUM.GRAPHICS].gradient_colors,
      METALLIC_COLORS,
      'all stops'
    )
  end)

  spec.it(
    'produces scalars or scalar lists so cache keys stay stable',
    function()
      for _, style in pairs(heading_style_resolver.resolve(STYLES, 1)) do
        for field_name, value in pairs(style) do
          if type(value) == 'table' then
            for _, item in ipairs(value) do
              expect.not_equal(
                type(item),
                'table',
                field_name .. ' item is scalar'
              )
            end
          end
        end
      end
    end
  )
end)
