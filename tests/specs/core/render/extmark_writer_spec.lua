local buffer_factory = require 'helpers.buffer_factory'
local expect = require 'harness.assertions'
local extmark_reader = require 'helpers.extmark_reader'
local extmark_writer = require 'scaled_markdown.core.render.extmark_writer'
local render_pipeline = require 'scaled_markdown.core.render.render_pipeline'
local spec = require 'harness.spec'

---@type string[]
local LINES = { 'first line', 'second line', 'third line' }
local REVEALED_ROW = 1
local TEXT_OFFSET = 3
local OUT_OF_RANGE_OFFSET = 10
local NEGATIVE_ROW = -5
---@type [string, string][]
local OVERLAY_TEXT = { { 'x', 'Normal' } }
---@type [string, string][][]
local ART_LINES = {
  { { 'a', 'Normal' } },
  { { 'b', 'Normal' } },
}

---@param buf integer
---@param revealed_rows? table<integer, boolean>
---@param text_offset? integer
---@return ExtmarkWriterProps
local function build_writer(buf, revealed_rows, text_offset)
  return extmark_writer.new(
    buf,
    render_pipeline.namespace_id(),
    revealed_rows or {},
    text_offset or 0
  )
end

spec.describe('extmark_writer', function()
  spec.it('writes extmarks on rows that are not revealed', function()
    local buf = buffer_factory.from_lines(LINES)
    local extmark_id = build_writer(buf).set_extmark(
      0,
      0,
      { virt_text = OVERLAY_TEXT, virt_text_pos = 'overlay' }
    )
    expect.truthy(extmark_id, 'extmark id returned')
    expect.equal(#extmark_reader.on_row(buf, 0), 1, 'extmark written')
  end)

  spec.it('skips decorations without height on revealed rows', function()
    local buf = buffer_factory.from_lines(LINES)
    local extmark_id = build_writer(buf, { [REVEALED_ROW] = true }).set_extmark(
      REVEALED_ROW,
      0,
      { virt_text = OVERLAY_TEXT, virt_text_pos = 'overlay' }
    )
    expect.is_nil(extmark_id, 'nothing written')
    expect.equal(#extmark_reader.list(buf), 0, 'no extmarks')
  end)

  spec.it(
    'keeps blank virtual lines on revealed rows to preserve height',
    function()
      local buf = buffer_factory.from_lines(LINES)
      build_writer(buf, { [REVEALED_ROW] = true }).set_extmark(
        REVEALED_ROW,
        0,
        {
          virt_text = OVERLAY_TEXT,
          virt_text_pos = 'overlay',
          virt_lines = ART_LINES,
        }
      )
      local details = extmark_reader.on_row(buf, REVEALED_ROW)[1].details
      expect.is_nil(details.virt_text, 'no overlay text')
      expect.equal(#details.virt_lines, #ART_LINES, 'same height')
      for _, virt_line in ipairs(details.virt_lines) do
        expect.equal(
          vim.trim(extmark_reader.virt_line_string(virt_line)),
          '',
          'blank'
        )
      end
    end
  )

  spec.it(
    'anchors virtual lines to the left column behind the gutter',
    function()
      local buf = buffer_factory.from_lines(LINES)
      build_writer(buf, {}, TEXT_OFFSET).set_extmark(
        0,
        0,
        { virt_lines = ART_LINES }
      )
      local details = extmark_reader.on_row(buf, 0)[1].details
      expect.truthy(details.virt_lines_leftcol, 'left column')
      expect.equal(
        details.virt_lines[1][1][1],
        string.rep(' ', TEXT_OFFSET),
        'gutter padding'
      )
      expect.equal(details.virt_lines[1][2][1], 'a', 'content after gutter')
    end
  )

  spec.it('clamps rows past the end of the buffer', function()
    local buf = buffer_factory.from_lines(LINES)
    local extmark_id = build_writer(buf).set_extmark(
      #LINES + OUT_OF_RANGE_OFFSET,
      0,
      { virt_lines = ART_LINES }
    )
    expect.truthy(extmark_id, 'clamped extmark written')
    expect.equal(
      extmark_reader.list(buf)[1].row,
      #LINES,
      'clamped to line count'
    )
  end)

  spec.it('swallows invalid positions instead of raising', function()
    local buf = buffer_factory.from_lines(LINES)
    ---@type integer
    local extmark_id
    expect.succeeds(
      function()
        extmark_id = build_writer(buf).set_extmark(
          NEGATIVE_ROW,
          0,
          { virt_lines = ART_LINES }
        )
      end,
      'negative row'
    )
    expect.is_nil(extmark_id, 'no extmark id')
  end)
end)
