local expect = require 'harness.assertions'
local mod_registry = require 'scaled_markdown.core.registry.mod_registry'
local spec = require 'harness.spec'

local HIGHLIGHT_GROUP = 'ScaledMarkdownSpecGroup'
local DYNAMIC_HIGHLIGHT_GROUP = 'ScaledMarkdownSpecDynamicGroup'
local VALID_QUERY = '(atx_heading) @heading'
local INVALID_QUERY = '(not_a_node) @x'
---@type table<string, any>
local INVALID_FIELD_VALUES = {
  name = 42,
  language = 'python',
  query = false,
  render = 'not a function',
}

---@param overrides? table<string, any>
---@return ModProps
local function build_mod(overrides)
  ---@type table<string, any>
  local base_mod = {
    name = 'sample',
    language = 'markdown',
    query = VALID_QUERY,
    render = function() end,
  }
  return vim.tbl_extend('force', base_mod, overrides or {})
end

---@return HighlightDefinitionsProps
local function build_dynamic_highlights()
  return { [DYNAMIC_HIGHLIGHT_GROUP] = { italic = true } }
end

spec.describe('mod_registry', function()
  spec.before_each(function() mod_registry.register_all {} end)

  spec.it('registers mods in order with a parsed query', function()
    mod_registry.register_all {
      build_mod { name = 'first' },
      build_mod { name = 'second' },
    }
    local registered = mod_registry.list()
    expect.equal(#registered, 2, 'two mods')
    expect.equal(registered[1].props.name, 'first', 'first order')
    expect.equal(registered[2].props.name, 'second', 'second order')
    expect.deep_equal(
      registered[1].query.captures,
      { 'heading' },
      'parsed query'
    )
  end)

  spec.it('replaces the previous registrations on register_all', function()
    mod_registry.register_all { build_mod { name = 'old' } }
    mod_registry.register_all { build_mod { name = 'new' } }
    expect.equal(#mod_registry.list(), 1, 'single mod')
    expect.equal(mod_registry.list()[1].props.name, 'new', 'new mod')
  end)

  spec.it('rejects mods with invalid required fields', function()
    for field_name, invalid_value in pairs(INVALID_FIELD_VALUES) do
      expect.fails(
        function()
          mod_registry.register(build_mod { [field_name] = invalid_value })
        end,
        field_name,
        ('invalid %s'):format(field_name)
      )
    end
  end)

  spec.it('rejects queries that do not parse', function()
    expect.fails(
      function() mod_registry.register(build_mod { query = INVALID_QUERY }) end,
      nil,
      'invalid query'
    )
  end)

  spec.it(
    'collects default configs, using an empty table when absent',
    function()
      mod_registry.register_all {
        build_mod { name = 'configured', default_config = { size = 3 } },
        build_mod { name = 'bare' },
      }
      local default_configs = mod_registry.collect_default_configs()
      expect.deep_equal(default_configs.configured, { size = 3 }, 'configured')
      expect.deep_equal(default_configs.bare, {}, 'bare')
    end
  )

  spec.it('collects static and function highlights', function()
    mod_registry.register_all {
      build_mod {
        name = 'static',
        highlights = { [HIGHLIGHT_GROUP] = { bold = true } },
      },
      build_mod { name = 'dynamic', highlights = build_dynamic_highlights },
      build_mod { name = 'none' },
    }
    local highlights = mod_registry.collect_highlights()
    expect.deep_equal(highlights[HIGHLIGHT_GROUP], { bold = true }, 'static')
    expect.deep_equal(
      highlights[DYNAMIC_HIGHLIGHT_GROUP],
      { italic = true },
      'dynamic'
    )
  end)
end)
