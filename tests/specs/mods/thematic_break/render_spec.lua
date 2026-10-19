local buffer_factory = require 'helpers.buffer_factory'
local expect = require 'harness.assertions'
local extmark_reader = require 'helpers.extmark_reader'
local plugin_session = require 'helpers.plugin_session'
local spec = require 'harness.spec'
local utf8_text = require 'scaled_markdown.core.text.utf8_text'
local window_geometry = require 'scaled_markdown.core.render.window_geometry'

local MOD_NAME = 'thematic_break'
---@type string[]
local LINES = { 'above', '', '---', '', 'below' }
local BREAK_ROW = 2
local DEFAULT_CHARACTER = '─'
local CUSTOM_CHARACTER = '='
---@type string[]
local BREAK_MARKERS = { '***', '___', '- - -' }

---@param lines string[]
---@param mod_config? ThematicBreakConfigProps
---@return integer
local function render(lines, mod_config)
  plugin_session.start_with_only(MOD_NAME, mod_config)
  local buf = buffer_factory.from_lines(lines)
  plugin_session.render(buf)
  return buf
end

---@param buf integer
---@return string
local function rendered_line(buf)
  local entry = extmark_reader.on_row(buf, BREAK_ROW)[1]
  return entry and extmark_reader.virt_text_string(entry.details)
end

spec.describe('thematic_break render', function()
  spec.it('draws a line across the whole text area', function()
    local line = rendered_line(render(LINES))
    local line_width = utf8_text.display_width(line)
    expect.equal(line_width, window_geometry.text_area_width(0), 'full width')
    expect.equal(line, string.rep(DEFAULT_CHARACTER, line_width), 'characters')
  end)

  spec.it('accepts every thematic break marker', function()
    for _, marker in ipairs(BREAK_MARKERS) do
      local buf = render { 'above', '', marker }
      expect.equal(
        #extmark_reader.on_row(buf, BREAK_ROW),
        1,
        marker .. ' rendered'
      )
    end
  end)

  spec.it(
    'uses the configured character',
    function()
      expect.matches(
        rendered_line(render(LINES, { character = CUSTOM_CHARACTER })),
        '^' .. CUSTOM_CHARACTER .. '+$',
        'custom character'
      )
    end
  )
end)
