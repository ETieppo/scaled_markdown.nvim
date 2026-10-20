local buffer_factory = require 'helpers.buffer_factory'
local expect = require 'harness.assertions'
local extmark_predicates = require 'helpers.extmark_predicates'
local extmark_reader = require 'helpers.extmark_reader'
local plugin_session = require 'helpers.plugin_session'
local spec = require 'harness.spec'
local utf8_text = require 'scaled_markdown.core.text.utf8_text'

local MOD_NAME = 'code_block'
local QUOTE_MOD_NAME = 'quote'
---@type string[]
local QUOTED_FENCED_LINES = { '> ```lua', '> local a = 1', '> ```' }
---@type string[]
local FENCED_LINES = { '```lua', 'local a = 1', '```' }
---@type string[]
local INDENTED_LINES = { 'para', '', '    code one', '    code two' }
local MIN_WIDTH = 20
local EXTRA_CONTENT_WIDTH = 10
local HUGE_CONTENT_WIDTH = 500
local BORDERS_AND_PADDING_WIDTH = 4
local CONTENT_ROW = 1
local VERTICAL_BORDER = '│'
local LUA_ICON = '\u{E620} '
local DEFAULT_ICON = '\u{F121} '

---@param lines string[]
---@param extra_config? table<string, any>
---@return integer
local function render(lines, extra_config)
  plugin_session.start_with_only(
    MOD_NAME,
    vim.tbl_extend('force', { min_width = MIN_WIDTH }, extra_config or {})
  )
  local buf = buffer_factory.from_lines(lines)
  plugin_session.render(buf)
  return buf
end

---@param buf integer
---@param row integer
---@return string
local function overlay_text_on_row(buf, row)
  local entry = extmark_reader.find(buf, extmark_predicates.overlay_on_row(row))
  return entry and extmark_reader.virt_text_string(entry.details)
end

---@param buf integer
---@param predicate ExtmarkPredicateProps
---@return string
local function virtual_border_text(buf, predicate)
  local entry = extmark_reader.find(buf, predicate)
  return vim.trim(extmark_reader.virt_line_string(entry.details.virt_lines[1]))
end

---@param buf integer
---@return string
local function top_border_text(buf)
  return virtual_border_text(buf, extmark_predicates.virt_lines_above)
end

---@param buf integer
---@return string
local function bottom_border_text(buf)
  return virtual_border_text(buf, extmark_predicates.virt_lines_below)
end

---@param border_text string
---@return integer
local function border_width(border_text)
  return utf8_text.display_width(border_text)
end

spec.describe('code_block render', function()
  spec.it('turns the fences into a titled top and a bottom border', function()
    local buf = render(FENCED_LINES)
    expect.truthy(
      vim.startswith(top_border_text(buf), '╭─ ' .. LUA_ICON .. 'lua '),
      'top'
    )
    expect.truthy(vim.startswith(bottom_border_text(buf), '╰─'), 'bottom')
    expect.equal(border_width(top_border_text(buf)), MIN_WIDTH, 'top width')
    expect.equal(
      border_width(bottom_border_text(buf)),
      MIN_WIDTH,
      'bottom width'
    )
  end)

  spec.it('hides both fences so the borders replace them', function()
    local buf = render(FENCED_LINES)
    local hidden_rows = vim.tbl_map(
      ---@param entry ExtmarkEntryProps
      ---@return integer
      function(entry) return entry.row end,
      extmark_reader.find_all(
        buf,
        ---@param details vim.api.keyset.set_extmark
        ---@return boolean
        function(details) return details.conceal_lines ~= nil end
      )
    )
    expect.deep_equal(hidden_rows, { 0, 2 }, 'fence rows')
    local top = extmark_reader.find(buf, extmark_predicates.virt_lines_above)
    local bottom = extmark_reader.find(buf, extmark_predicates.virt_lines_below)
    expect.equal(top.row, CONTENT_ROW, 'top border above content')
    expect.equal(bottom.row, CONTENT_ROW, 'bottom border below content')
  end)

  spec.it('shows the default icon for unknown languages', function()
    local buf = render { '```brainfuck', '+', '```' }
    expect.truthy(
      vim.startswith(
        top_border_text(buf),
        '╭─ ' .. DEFAULT_ICON .. 'brainfuck '
      ),
      'default icon'
    )
  end)

  spec.it('matches language icons case-insensitively', function()
    local buf = render { '```Python', 'pass', '```' }
    expect.matches(top_border_text(buf), '\u{E606} Python', 'icon')
  end)

  spec.it('uses configured language icons', function()
    local buf = render(FENCED_LINES, { language_icons = { lua = '☾ ' } })
    expect.truthy(
      vim.startswith(top_border_text(buf), '╭─ ☾ lua '),
      'custom icon'
    )
  end)

  spec.it('keeps blocks without a language untitled', function()
    local buf = render { '```', 'plain', '```' }
    expect.truthy(vim.startswith(top_border_text(buf), '╭──'), 'no title')
  end)

  spec.it('adds side borders to every content row', function()
    local buf = render(FENCED_LINES)
    local spacer =
      extmark_reader.find(buf, extmark_predicates.inline_on_row(CONTENT_ROW))
    ---@type table<integer, string>
    local border_by_column = {}
    for _, entry in
      ipairs(extmark_reader.find_all(
        buf,
        ---@param details vim.api.keyset.set_extmark
        ---@param entry ExtmarkEntryProps
        ---@return boolean
        function(details, entry)
          return entry.row == CONTENT_ROW and details.virt_text_win_col ~= nil
        end
      ))
    do
      border_by_column[entry.details.virt_text_win_col] =
        entry.details.virt_text[1][1]
    end
    expect.equal(spacer.details.virt_text[1][1], ' ', 'left border spacer')
    expect.equal(spacer.details.virt_text[2][1], ' ', 'padding')
    expect.deep_equal(border_by_column, {
      [0] = VERTICAL_BORDER,
      [MIN_WIDTH - 1] = VERTICAL_BORDER,
    }, 'border columns')
  end)

  spec.it('grows the box to fit the widest content line', function()
    local long_line = string.rep('x', MIN_WIDTH + EXTRA_CONTENT_WIDTH)
    expect.equal(
      border_width(top_border_text(render { '```', long_line, '```' })),
      #long_line + BORDERS_AND_PADDING_WIDTH,
      'content plus borders'
    )
  end)

  spec.it('never exceeds the window text area', function()
    local buf = render { '```', string.rep('x', HUGE_CONTENT_WIDTH), '```' }
    expect.truthy(
      border_width(top_border_text(buf)) <= vim.api.nvim_win_get_width(0),
      'clamped to window'
    )
  end)

  spec.it('draws virtual borders around indented blocks', function()
    local buf = render(INDENTED_LINES)
    local above = extmark_reader.find(buf, extmark_predicates.virt_lines_above)
    local below = extmark_reader.find(buf, extmark_predicates.virt_lines_below)
    expect.equal(above.row, 2, 'top border above first row')
    expect.equal(below.row, 3, 'bottom border below last row')
    expect.matches(
      extmark_reader.virt_line_string(above.details.virt_lines[1]),
      '╭',
      'top'
    )
    expect.matches(
      extmark_reader.virt_line_string(below.details.virt_lines[1]),
      '╰',
      'bottom'
    )
  end)

  spec.it('continues the quote bar on borders inside quotes', function()
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
      reveal = { cursor_line = false, visual_selection = false },
      mods = mods_config,
    }
    local buf = buffer_factory.from_lines(QUOTED_FENCED_LINES)
    plugin_session.render(buf)
    local bar = (
      plugin_session.mod_config(QUOTE_MOD_NAME) --[[@as QuoteConfigProps]]
    ).bar
    for _, predicate in ipairs {
      extmark_predicates.virt_lines_above,
      extmark_predicates.virt_lines_below,
    } do
      local border = extmark_reader.find(buf, predicate)
      expect.truthy(
        vim.startswith(
          extmark_reader.virt_line_string(border.details.virt_lines[1]),
          bar .. ' '
        ),
        'bar before border'
      )
    end
  end)

  spec.it('renders empty fenced blocks without errors', function()
    local buf = render { '```', '```' }
    expect.truthy(overlay_text_on_row(buf, 0), 'top border')
    expect.truthy(overlay_text_on_row(buf, 1), 'bottom border')
  end)
end)
