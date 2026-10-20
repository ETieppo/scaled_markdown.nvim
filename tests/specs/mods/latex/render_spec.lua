local buffer_factory = require 'helpers.buffer_factory'
local expect = require 'harness.assertions'
local extmark_predicates = require 'helpers.extmark_predicates'
local extmark_reader = require 'helpers.extmark_reader'
local plugin_session = require 'helpers.plugin_session'
local spec = require 'harness.spec'

local MOD_NAME = 'latex'
local QUOTE_MOD_NAME = 'quote'
local MATH_GROUP = 'ScaledMarkdownLatex'
local MATH_GROUP_PATTERN = '^ScaledMarkdownLatex'
local NUMBER_GROUP = 'ScaledMarkdownLatexNumber'
local RELATION_GROUP = 'ScaledMarkdownLatexRelation'
local INLINE_LINE = 'mass $E = mc^2$ here'
local INLINE_START_COLUMN = 5
local INLINE_END_COLUMN = 15
---@type string[]
local DISPLAY_LINES = { '$$', [[\frac{1}{2}]], '$$' }
---@type string[]
local DISPLAY_BOX_LINES = { ' 1', '───', ' 2' }
---@type integer[]
local DISPLAY_CONCEALED_ROWS = { 0, 1, 2 }
---@type string[]
local QUOTED_DISPLAY_LINES = { '> [!NOTE]', '> $$', '> x^2', '> $$' }
local QUOTED_TEXT = 'x²'
local QUOTE_PREFIX_WIDTH = 2
---@type RevealProps
local NO_REVEAL = { cursor_line = false, visual_selection = false }

local function start_with_quote()
  plugin_session.start()
  ---@type table<string, ModConfigProps>
  local mods_config = {}
  for _, name in ipairs(plugin_session.mod_names()) do
    mods_config[name] = {
      enabled = name == MOD_NAME or name == QUOTE_MOD_NAME,
    }
  end
  plugin_session.start {
    renderer = 'plain',
    reveal = NO_REVEAL,
    mods = mods_config,
  }
end

---@param lines string[]
---@param mod_config? table<string, any>
---@return integer
local function render(lines, mod_config)
  plugin_session.start_with_only(MOD_NAME, mod_config)
  local buf = buffer_factory.from_lines(lines)
  plugin_session.render(buf)
  return buf
end

---@param buf integer
---@return ExtmarkEntryProps
local function find_math_text(buf)
  return extmark_reader.find(
    buf,
    ---@param details vim.api.keyset.set_extmark
    ---@return boolean
    function(details)
      return extmark_predicates.is_inline(details)
        and details.virt_text[1][2]:match(MATH_GROUP_PATTERN) ~= nil
    end
  )
end

---@param buf integer
---@return string[]
local function math_lines_by_row(buf)
  ---@type string[]
  local lines = {}
  for _, entry in ipairs(extmark_reader.list(buf)) do
    local chunks = entry.details.virt_text
    if chunks and chunks[1] and chunks[1][2]:match(MATH_GROUP_PATTERN) then
      lines[entry.row + 1] = extmark_reader.virt_text_string(entry.details)
    end
  end
  return lines
end

---@param buf integer
---@return integer[]
local function concealed_rows(buf)
  return vim.tbl_map(
    ---@param entry ExtmarkEntryProps
    ---@return integer
    function(entry) return entry.row end,
    extmark_reader.find_all(buf, extmark_predicates.has_conceal)
  )
end

spec.describe('latex render', function()
  spec.it('replaces inline math with its unicode form', function()
    local buf = render { INLINE_LINE }
    local conceal = extmark_reader.find(buf, extmark_predicates.has_conceal)
    expect.equal(conceal.col, INLINE_START_COLUMN, 'conceal start')
    expect.equal(conceal.details.end_col, INLINE_END_COLUMN, 'conceal end')
    local math_text = find_math_text(buf)
    expect.equal(math_text.col, INLINE_START_COLUMN, 'text column')
    expect.equal(
      extmark_reader.virt_text_string(math_text.details),
      'E = mc²',
      'text'
    )
  end)

  spec.it('highlights symbols by class', function()
    local math_text = find_math_text(render { INLINE_LINE })
    expect.deep_equal(math_text.details.virt_text, {
      { 'E ', MATH_GROUP },
      { '=', RELATION_GROUP },
      { ' mc', MATH_GROUP },
      { '²', NUMBER_GROUP },
    }, 'chunks')
  end)

  spec.it('uses one highlight when symbol highlighting is off', function()
    local math_text =
      find_math_text(render({ INLINE_LINE }, { highlight_symbols = false }))
    expect.deep_equal(
      math_text.details.virt_text,
      { { 'E = mc²', MATH_GROUP } },
      'single chunk'
    )
  end)

  spec.it('stacks display fractions over the source rows', function()
    local buf = render(DISPLAY_LINES)
    expect.deep_equal(concealed_rows(buf), DISPLAY_CONCEALED_ROWS, 'rows')
    expect.deep_equal(math_lines_by_row(buf), DISPLAY_BOX_LINES, 'box lines')
  end)

  spec.it('centers display math when enabled', function()
    local buf = render(DISPLAY_LINES, { center_display_math = true })
    for _, line in ipairs(math_lines_by_row(buf)) do
      expect.matches(line, '^  +', 'leading padding')
    end
  end)

  spec.it(
    'renders display math sharing a row with prose on one line',
    function()
      local math_text = find_math_text(render { [[see $$\frac{1}{2}$$ here]] })
      expect.equal(
        extmark_reader.virt_text_string(math_text.details),
        '¹⁄₂',
        'linear text'
      )
    end
  )

  spec.it('lays out inline math alone on its line in two dimensions', function()
    local buf = render { [[$\sqrt{3x-1}+(1+x)^2$]] }
    expect.deep_equal(
      math_lines_by_row(buf),
      { '√3x − 1 + (1 + x)²' },
      'baseline on the source row'
    )
    local bar = extmark_reader.find(buf, extmark_predicates.virt_lines_above)
    expect.equal(
      extmark_reader.virt_line_string(bar.details.virt_lines[1]),
      ' ______',
      'bar above'
    )
  end)

  spec.it('places fraction parts around a single source row', function()
    local buf = render { [[$$\frac{a}{b}$$]] }
    expect.deep_equal(
      math_lines_by_row(buf),
      { '───' },
      'rule on the row'
    )
    expect.truthy(
      extmark_reader.find(buf, extmark_predicates.virt_lines_above),
      'numerator above'
    )
    expect.truthy(
      extmark_reader.find(buf, extmark_predicates.virt_lines_below),
      'denominator below'
    )
  end)

  spec.it('overlines roots of inline math inside prose', function()
    local math_text = find_math_text(render { [[root $\sqrt{x+1}$ here]] })
    expect.equal(
      extmark_reader.virt_text_string(math_text.details),
      '√x\u{0305}+\u{0305}1\u{0305}',
      'overlined radicand'
    )
  end)

  spec.it('uses configured command symbols', function()
    local math_text = find_math_text(
      render({ [[$\star$]] }, { command_symbols = { star = '★' } })
    )
    expect.equal(
      extmark_reader.virt_text_string(math_text.details),
      '★',
      'custom symbol'
    )
  end)

  spec.it('ignores dollar amounts in prose', function()
    local buf = render { 'cost $5 and $10 today' }
    expect.deep_equal(extmark_reader.list(buf), {}, 'no extmarks')
  end)

  spec.it('ignores inline math wrapped in spaces', function()
    local buf = render { 'a $ x $ b' }
    expect.deep_equal(extmark_reader.list(buf), {}, 'no extmarks')
  end)

  spec.it('keeps quote prefixes out of quoted display math', function()
    start_with_quote()
    local buf = buffer_factory.from_lines(QUOTED_DISPLAY_LINES)
    plugin_session.render(buf)
    local math_text = find_math_text(buf)
    expect.truthy(math_text, 'math text')
    expect.equal(
      vim.trim(extmark_reader.virt_text_string(math_text.details)),
      QUOTED_TEXT,
      'text'
    )
    for row = 2, #QUOTED_DISPLAY_LINES - 1 do
      local conceal = extmark_reader.find(
        buf,
        ---@param details vim.api.keyset.set_extmark
        ---@param entry ExtmarkEntryProps
        ---@return boolean
        function(details, entry)
          return entry.row == row and details.conceal ~= nil
        end
      )
      expect.equal(conceal.col, QUOTE_PREFIX_WIDTH, 'conceal after prefix')
    end
    for row = 0, #QUOTED_DISPLAY_LINES - 1 do
      expect.truthy(
        extmark_reader.find(buf, extmark_predicates.overlay_on_row(row)),
        ('quote bar on row %d'):format(row)
      )
    end
  end)

  spec.it('ignores unclosed math', function()
    local buf = render { 'cost $5 only' }
    expect.deep_equal(extmark_reader.list(buf), {}, 'no extmarks')
  end)
end)
