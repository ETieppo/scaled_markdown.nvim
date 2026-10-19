local RENDERER_ENUM = require 'scaled_markdown.core.enums.renderer_enum'
local buffer_factory = require 'helpers.buffer_factory'
local environment = require 'helpers.environment'
local expect = require 'harness.assertions'
local extmark_reader = require 'helpers.extmark_reader'
local heading_art = require 'helpers.heading_art'
local plugin_session = require 'helpers.plugin_session'
local spec = require 'harness.spec'

local REQUIRED_FONT = 'FreeSans:bold'
local WRAP_WIDTH = 80
local PRIMARY_LEVEL = 1
local SAME_HEIGHT_LEVEL = 2
---@type string[]
local SAME_HEIGHT_SAMPLES = { 'summer', 'Heading', '50% @a \\ b' }
local PRIMARY_HEADING = 'Primary Heading'
local LONG_PRIMARY_HEADING = 'Install and Configure the Plugin Today'
local SHORT_SECONDARY_HEADING = 'Setup'
---@type string[]
local HEADING_LINES = { '# Primary Heading', '', 'text' }

---@return integer
local function primary_rows()
  local heading_config = plugin_session.mod_config 'heading' --[[@as HeadingConfigProps]]
  return heading_config.styles[RENDERER_ENUM.TYPEFACE].rows_by_level[PRIMARY_LEVEL]
end

spec.describe('typeface renderer', function()
  spec.before_each(function()
    spec.skip_unless(
      environment.has_font(REQUIRED_FONT),
      environment.missing_font_reason(REQUIRED_FONT)
    )
    plugin_session.start { renderer = RENDERER_ENUM.TYPEFACE }
  end)

  spec.it('draws ink on the first art row', function()
    local art = heading_art.request(PRIMARY_HEADING, PRIMARY_LEVEL, WRAP_WIDTH)
    expect.truthy(art, 'art produced')
    ---@cast art -nil
    expect.not_equal(vim.trim(art.lines[1]), '', 'first row has ink')
  end)

  spec.it('keeps the level height for any glyph mix', function()
    ---@type integer
    local expected_height
    for _, sample in ipairs(SAME_HEIGHT_SAMPLES) do
      local art = heading_art.request(sample, SAME_HEIGHT_LEVEL, WRAP_WIDTH)
      expect.truthy(art, ("art for '%s'"):format(sample))
      ---@cast art -nil
      expected_height = expected_height or #art.lines
      expect.equal(
        #art.lines,
        expected_height,
        ("height of '%s'"):format(sample)
      )
    end
  end)

  spec.it('wraps long headings into whole level sized lines', function()
    local rows = primary_rows()
    local long_art = assert(
      heading_art.request(LONG_PRIMARY_HEADING, PRIMARY_LEVEL, WRAP_WIDTH)
    )
    local short_art = assert(
      heading_art.request(
        SHORT_SECONDARY_HEADING,
        SAME_HEIGHT_LEVEL,
        WRAP_WIDTH
      )
    )
    expect.at_least(#long_art.lines, rows * 2, 'wrapped into lines')
    expect.equal(#long_art.lines % rows, 0, 'each line keeps level rows')
    expect.truthy(#long_art.lines > #short_art.lines, 'primary stays taller')
  end)

  spec.it('fits the art inside the requested width', function()
    local art = assert(
      heading_art.request(LONG_PRIMARY_HEADING, PRIMARY_LEVEL, WRAP_WIDTH)
    )
    for _, line in ipairs(art.lines) do
      expect.truthy(vim.fn.strdisplaywidth(line) <= WRAP_WIDTH, 'line fits')
    end
  end)

  spec.it('keeps a blank height placeholder on the revealed heading', function()
    local buf = buffer_factory.from_lines(HEADING_LINES)
    buffer_factory.move_cursor_away(buf)
    plugin_session.render_until_settled(buf)
    local rendered = extmark_reader.on_row(buf, 0)[1]
    expect.truthy(rendered.details.virt_text, 'art overlay when not revealed')
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    plugin_session.render_until_settled(buf)
    local placeholder = extmark_reader.on_row(buf, 0)[1]
    expect.is_nil(placeholder.details.virt_text, 'source visible')
    expect.equal(
      #placeholder.details.virt_lines,
      #rendered.details.virt_lines,
      'same height'
    )
  end)
end)
