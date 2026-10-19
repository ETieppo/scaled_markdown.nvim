local TABLE_QUERY = require 'scaled_markdown.mods.table.query'
local capture_builder = require 'helpers.capture_builder'
local expect = require 'harness.assertions'
local spec = require 'harness.spec'
local table_dto_builder = require 'scaled_markdown.mods.table.table_dto_builder'

local MIN_COLUMN_WIDTH = 3
---@type string[]
local TABLE_LINES = {
  '| Name | Value | Notes |',
  '| :--- | :---: | ----: |',
  '| alpha | 1 | first |',
  '| beta | 22 | second row |',
}

---@param lines string[]
---@param min_column_width? integer
---@return TableProps
local function build_table_dto(lines, min_column_width)
  local captures, buf = capture_builder.from_lines(lines, TABLE_QUERY)
  return table_dto_builder.build(
    captures[1],
    buf,
    min_column_width or MIN_COLUMN_WIDTH
  )
end

spec.describe('table_dto_builder', function()
  spec.it('reads row kinds and rows in source order', function()
    local table_dto = build_table_dto(TABLE_LINES)
    expect.deep_equal(
      vim.tbl_map(
        ---@param row_dto TableRowProps
        ---@return string
        function(row_dto) return row_dto.kind end,
        table_dto.rows
      ),
      { 'header', 'delimiter', 'body', 'body' },
      'row kinds'
    )
    expect.deep_equal(
      vim.tbl_map(
        ---@param row_dto TableRowProps
        ---@return integer
        function(row_dto) return row_dto.row end,
        table_dto.rows
      ),
      { 0, 1, 2, 3 },
      'row numbers'
    )
  end)

  spec.it('reads trimmed cell texts', function()
    local table_dto = build_table_dto(TABLE_LINES)
    expect.deep_equal(
      table_dto.rows[1].cells,
      { 'Name', 'Value', 'Notes' },
      'header'
    )
    expect.deep_equal(
      table_dto.rows[4].cells,
      { 'beta', '22', 'second row' },
      'body'
    )
  end)

  spec.it(
    'reads left, center and right alignments',
    function()
      expect.deep_equal(
        build_table_dto(TABLE_LINES).alignments,
        { 'left', 'center', 'right' },
        'alignments'
      )
    end
  )

  spec.it(
    'defaults unmarked columns to left alignment',
    function()
      expect.deep_equal(
        build_table_dto({ '| a | b |', '| --- | --- |' }).alignments,
        { 'left', 'left' },
        'default alignment'
      )
    end
  )

  spec.it('sizes columns by the widest cell with a minimum', function()
    expect.deep_equal(
      build_table_dto(TABLE_LINES).column_widths,
      { 5, 5, 10 },
      'widths'
    )
    expect.deep_equal(
      build_table_dto({ '| a | b |', '| - | - |' }, 4).column_widths,
      { 4, 4 },
      'minimum width'
    )
  end)

  spec.it(
    'measures wide characters by display width',
    function()
      expect.deep_equal(
        build_table_dto({ '| 漢字 |', '| --- |' }, 1).column_widths,
        { 4 },
        'display width'
      )
    end
  )
end)
