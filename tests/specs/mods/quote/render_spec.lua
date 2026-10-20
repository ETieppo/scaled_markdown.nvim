local buffer_factory = require 'helpers.buffer_factory'
local expect = require 'harness.assertions'
local extmark_predicates = require 'helpers.extmark_predicates'
local extmark_reader = require 'helpers.extmark_reader'
local plugin_session = require 'helpers.plugin_session'
local spec = require 'harness.spec'

local MOD_NAME = 'quote'
local GRADIENT_PATTERN = '^ScaledMarkdownGradient%d+$'
local NOTE_TYPE = 'NOTE'
---@type integer[]
local NESTED_BAR_COLUMNS = { 0, 2 }
local CALLOUT_MARKER_START = 2
local CALLOUT_MARKER_END = 9

---@param lines string[]
---@return integer
local function render(lines)
  local buf = buffer_factory.from_lines(lines)
  plugin_session.render(buf)
  return buf
end

---@param buf integer
---@param row integer
---@return ExtmarkEntryProps[]
local function bars_on_row(buf, row)
  return extmark_reader.find_all(buf, extmark_predicates.overlay_on_row(row))
end

---@param buf integer
---@param row integer
---@return string
local function first_bar_group(buf, row)
  return bars_on_row(buf, row)[1].details.virt_text[1][2]
end

---@param buf integer
---@return ExtmarkEntryProps
local function find_callout_title(buf)
  return extmark_reader.find(buf, extmark_predicates.is_inline)
end

spec.describe('quote render', function()
  spec.before_each(function() plugin_session.start_with_only(MOD_NAME) end)

  spec.it('overlays a gradient bar on every quote marker', function()
    local buf = render { '> one', '> two', '> three' }
    local bar = (plugin_session.mod_config(MOD_NAME) --[[@as QuoteConfigProps]]).bar
    for row = 0, 2 do
      local bars = bars_on_row(buf, row)
      expect.equal(#bars, 1, ('one bar on row %d'):format(row))
      expect.equal(bars[1].col, 0, 'bar column')
      expect.equal(bars[1].details.virt_text[1][1], bar, 'bar text')
      expect.matches(first_bar_group(buf, row), GRADIENT_PATTERN, 'gradient')
    end
  end)

  spec.it('draws one bar per nesting level without duplicates', function()
    local buf = render { '> outer', '> > inner' }
    expect.equal(#bars_on_row(buf, 0), 1, 'outer row')
    local inner_columns = vim.tbl_map(
      ---@param entry ExtmarkEntryProps
      ---@return integer
      function(entry) return entry.col end,
      bars_on_row(buf, 1)
    )
    table.sort(inner_columns)
    expect.deep_equal(inner_columns, NESTED_BAR_COLUMNS, 'bar columns')
  end)

  spec.it('renders callouts with icon, title and callout color', function()
    local buf = render { '> [!NOTE]', '> body' }
    local callout = (
      plugin_session.mod_config(MOD_NAME) --[[@as QuoteConfigProps]]
    ).callouts[NOTE_TYPE]
    expect.deep_equal(
      find_callout_title(buf).details.virt_text,
      { { callout.icon .. callout.title, callout.color } },
      'title chunk'
    )
    local marker = extmark_reader.find(buf, extmark_predicates.has_conceal)
    expect.equal(marker.col, CALLOUT_MARKER_START, 'marker start')
    expect.equal(marker.details.end_col, CALLOUT_MARKER_END, 'marker end')
    for row = 0, 1 do
      expect.equal(
        first_bar_group(buf, row),
        callout.color,
        'callout colored bar'
      )
    end
  end)

  spec.it(
    'accepts lower case callout types',
    function()
      expect.truthy(
        find_callout_title(render { '> [!note]', '> body' }),
        'callout title'
      )
    end
  )

  spec.it('treats unknown callout types as plain quotes', function()
    local buf = render { '> [!UNKNOWN]', '> body' }
    expect.is_nil(find_callout_title(buf), 'no callout title')
    expect.matches(first_bar_group(buf, 0), GRADIENT_PATTERN, 'gradient bar')
  end)

  spec.it(
    'ignores callout markers that are not at the start',
    function()
      expect.is_nil(find_callout_title(render { '> text [!NOTE]' }), 'no title')
    end
  )
end)
