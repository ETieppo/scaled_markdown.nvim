local expect = require 'harness.assertions'
local line_prefix_decorator =
  require 'scaled_markdown.core.render.line_prefix_decorator'
local plugin_session = require 'helpers.plugin_session'
local spec = require 'harness.spec'

local PADDING_HIGHLIGHT = 'Normal'
local PREFIX_LINE = '  > text'
local PREFIX_COL = 4
---@type [string, string][]
local DECORATED_CHUNKS = { { '▌', 'Decorated' } }

---@param decorate_line_prefix? fun(row: integer, prefix_col: integer, context_dto: RenderContextProps<ModConfigProps>): [string, string][]?
---@return RegisteredModProps
local function fake_mod(decorate_line_prefix)
  return {
    props = {
      name = 'fake_prefix_mod',
      language = 'markdown',
      query = '',
      default_config = {},
      render = function() end,
      decorate_line_prefix = decorate_line_prefix,
    },
    query = vim.treesitter.query.parse('markdown', ''),
  }
end

---@param registered_mods RegisteredModProps[]
---@return fun(row: integer, prefix_col: integer): [string, string][]
local function build_decorator(registered_mods)
  return line_prefix_decorator.new(
    registered_mods,
    function() return PREFIX_LINE end,
    function(mod_config) return { mod_config = mod_config } end
  )
end

spec.describe('line_prefix_decorator', function()
  spec.before_each(function() plugin_session.start() end)

  spec.it('uses the first mod that decorates the prefix', function()
    local decorate = build_decorator {
      fake_mod(function() return nil end),
      fake_mod(function() return DECORATED_CHUNKS end),
    }
    expect.deep_equal(decorate(0, PREFIX_COL), DECORATED_CHUNKS, 'chunks')
  end)

  spec.it('falls back to blank padding of the prefix width', function()
    local decorate = build_decorator { fake_mod() }
    expect.deep_equal(
      decorate(0, PREFIX_COL),
      { { '    ', PADDING_HIGHLIGHT } },
      'blank prefix'
    )
  end)

  spec.it('ignores decorators that raise errors', function()
    local decorate = build_decorator {
      fake_mod(function() error 'broken decorator' end),
    }
    expect.deep_equal(
      decorate(0, PREFIX_COL),
      { { '    ', PADDING_HIGHLIGHT } },
      'blank prefix'
    )
  end)
end)
