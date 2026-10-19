local buffer_factory = require 'helpers.buffer_factory'
local expect = require 'harness.assertions'
local extmark_predicates = require 'helpers.extmark_predicates'
local extmark_reader = require 'helpers.extmark_reader'
local plugin_session = require 'helpers.plugin_session'
local spec = require 'harness.spec'
local utf8_text = require 'scaled_markdown.core.text.utf8_text'

local MOD_NAME = 'table'
---@type string[]
local TABLE_LINES = {
  '| Name | Value | Notes |',
  '| :--- | :---: | ----: |',
  '| alpha | 1 | first |',
}
local HEADER_GROUP = 'ScaledMarkdownTableHeaderCell'
local BODY_GROUP = 'ScaledMarkdownTableBodyCell'
local WIDE_SOURCE_LINE = '| a      |      b |'
local INLINE_CODE_GROUP = 'ScaledMarkdownTableInlineCode'
---@type string[]
local INLINE_CODE_TABLE_LINES = {
  '| Name | `Code` |',
  '| :--- | -----: |',
  '| alpha | `x = 1` and `y` |',
}

---@param lines string[]
---@param mod_config? TableConfigProps
---@return integer
local function render(lines, mod_config)
  plugin_session.start_with_only(MOD_NAME, mod_config)
  local buf = buffer_factory.from_lines(lines)
  plugin_session.render(buf)
  return buf
end

---@param buf integer
---@param row integer
---@return vim.api.keyset.set_extmark
local function overlay_details(buf, row)
  return extmark_reader.find(buf, extmark_predicates.overlay_on_row(row)).details
end

---@param buf integer
---@param row integer
---@return string
local function row_text(buf, row)
  return vim.trim(extmark_reader.virt_text_string(overlay_details(buf, row)))
end

---@param buf integer
---@param row integer
---@param highlight_group string
---@return string[]
local function chunk_texts_with_group(buf, row, highlight_group)
  ---@type string[]
  local texts = {}
  for _, chunk in ipairs(overlay_details(buf, row).virt_text) do
    if chunk[2] == highlight_group then texts[#texts + 1] = chunk[1] end
  end
  return texts
end

---@param buf integer
---@param row integer
---@return string[]
local function row_groups(buf, row)
  return vim.tbl_map(
    ---@param chunk [string, string]
    ---@return string
    function(chunk) return chunk[2] end,
    overlay_details(buf, row).virt_text
  )
end

spec.describe('table render', function()
  spec.it('draws aligned cells between vertical borders', function()
    local buf = render(TABLE_LINES)
    expect.equal(
      row_text(buf, 0),
      '│ Name  │ Value │ Notes │',
      'header row'
    )
    expect.equal(
      row_text(buf, 2),
      '│ alpha │   1   │ first │',
      'aligned body'
    )
  end)

  spec.it(
    'turns the delimiter row into a grid separator',
    function()
      expect.equal(
        row_text(render(TABLE_LINES), 1),
        '├───────┼───────┼───────┤',
        'separator'
      )
    end
  )

  spec.it('uses header and body cell groups', function()
    local buf = render(TABLE_LINES)
    expect.contains(row_groups(buf, 0), HEADER_GROUP, 'header group')
    expect.contains(row_groups(buf, 2), BODY_GROUP, 'body group')
  end)

  spec.it('adds top and bottom borders as virtual lines', function()
    local buf = render(TABLE_LINES)
    local top = extmark_reader.find(buf, extmark_predicates.virt_lines_above)
    local bottom = extmark_reader.find(buf, extmark_predicates.virt_lines_below)
    expect.equal(top.row, 0, 'top above header')
    expect.equal(bottom.row, #TABLE_LINES - 1, 'bottom below last row')
    expect.matches(
      extmark_reader.virt_line_string(top.details.virt_lines[1]),
      '╭───────┬───────┬───────╮',
      'top line'
    )
    expect.matches(
      extmark_reader.virt_line_string(bottom.details.virt_lines[1]),
      '╰───────┴───────┴───────╯',
      'bottom line'
    )
  end)

  spec.it('covers the whole source line of short rendered rows', function()
    local buf = render(
      { WIDE_SOURCE_LINE, '| - | - |' },
      { cell_padding = 0, min_column_width = 1 }
    )
    expect.at_least(
      utf8_text.display_width(
        extmark_reader.virt_text_string(overlay_details(buf, 0))
      ),
      utf8_text.display_width(WIDE_SOURCE_LINE),
      'source hidden'
    )
  end)

  spec.it('renders inline code in cells without backticks', function()
    local buf = render(INLINE_CODE_TABLE_LINES)
    expect.equal(
      row_text(buf, 0),
      '│ Name  │        Code │',
      'header code'
    )
    expect.equal(row_text(buf, 2), '│ alpha │ x = 1 and y │', 'body code')
  end)

  spec.it(
    'highlights inline code in cells with the inline code group',
    function()
      local buf = render(INLINE_CODE_TABLE_LINES)
      expect.deep_equal(
        chunk_texts_with_group(buf, 0, INLINE_CODE_GROUP),
        { 'Code' },
        'header code chunk'
      )
      expect.deep_equal(
        chunk_texts_with_group(buf, 2, INLINE_CODE_GROUP),
        { 'x = 1', 'y' },
        'body code chunks'
      )
      expect.contains(
        row_groups(buf, 2),
        BODY_GROUP,
        'plain text keeps body group'
      )
    end
  )
end)
