local RENDERER_ENUM = require 'scaled_markdown.core.enums.renderer_enum'
local buffer_factory = require 'helpers.buffer_factory'
local environment = require 'helpers.environment'
local expect = require 'harness.assertions'
local extmark_reader = require 'helpers.extmark_reader'
local glyph_run_rasterizer =
  require 'scaled_markdown.core.raster.glyph_run_rasterizer'
local graphics_renderer =
  require 'scaled_markdown.core.text_art.graphics_renderer'
local plugin_session = require 'helpers.plugin_session'
local spec = require 'harness.spec'
local stub = require 'harness.stub'
local terminal_capability =
  require 'scaled_markdown.core.terminal.terminal_capability'
local text_art_service =
  require 'scaled_markdown.core.text_art.text_art_service'

local REQUIRED_FONT = 'FreeSans:bold'
local PLACEHOLDER = vim.fn.nr2char(0x10EEEE)
local IMAGE_HIGHLIGHT_PATTERN = '^ScaledMarkdownImage%d+$'
local TRANSMIT_MARKER = 'a=T,U=1'
local DELETE_MARKER = 'a=d,d=I'
local GRAPHICS_WIDTH = 60
local TEXT_ART_WAIT_MS = 10000
local PRIMARY_HEADING_IMAGE_ROWS = 3
local SETTLED_RERENDERS = 3
local PRIMARY_HEADING = 'Primary Heading'
---@type TextArtStyleProps
local GRAPHICS_STYLE = {
  font = REQUIRED_FONT,
  line_height_cells = 3,
  gradient_colors = { '#7aa2f7', '#bb9af7' },
}
---@type string[]
local HEADING_LINES = {
  '# Primary Heading',
  '',
  '## Secondary Heading',
  '',
  'text',
}
local NO_CURSOR_REVEAL = { cursor_line = false, visual_selection = false }

---@return string[]
local function capture_terminal_payloads()
  ---@type string[]
  local payloads = {}
  stub.replace(
    vim.api,
    'nvim_ui_send',
    ---@param payload string
    function(payload) payloads[#payloads + 1] = payload end
  )
  return payloads
end

---@param payloads string[]
---@param marker string
---@return boolean
local function has_payload(payloads, marker)
  for _, payload in ipairs(payloads) do
    if payload:find(marker, 1, true) then return true end
  end
  return false
end

---@param text string
---@return TextArtProps?
local function render_graphics_async(text)
  ---@type TextArtProps?
  local text_art_dto = nil
  local is_done = false
  graphics_renderer.render_async(
    text,
    GRAPHICS_STYLE,
    GRAPHICS_WIDTH,
    ---@param result TextArtProps?
    function(result)
      text_art_dto, is_done = result, true
    end
  )
  vim.wait(TEXT_ART_WAIT_MS, function() return is_done end)
  return text_art_dto
end

spec.describe('graphics renderer', function()
  ---@type string[]
  local payloads

  spec.before_each(function()
    spec.skip_unless(
      environment.has_font(REQUIRED_FONT),
      environment.missing_font_reason(REQUIRED_FONT)
    )
    payloads = capture_terminal_payloads()
    stub.replace(
      terminal_capability,
      'supports_kitty_graphics',
      ---@return boolean
      function() return true end
    )
    plugin_session.start {
      renderer = RENDERER_ENUM.GRAPHICS,
      reveal = NO_CURSOR_REVEAL,
    }
  end)

  spec.it('produces placeholder rows matching the line height', function()
    local art = render_graphics_async(PRIMARY_HEADING)
    expect.truthy(art, 'placeholders produced')
    ---@cast art -nil
    expect.equal(#art.lines, GRAPHICS_STYLE.line_height_cells, 'rows')
    expect.matches(art.highlight, IMAGE_HIGHLIGHT_PATTERN, 'image id group')
  end)

  spec.it('transmits a virtual placement to the terminal', function()
    render_graphics_async(PRIMARY_HEADING)
    expect.truthy(has_payload(payloads, TRANSMIT_MARKER), 'virtual placement')
  end)

  spec.it('overlays placeholder cells with the image id highlight', function()
    local buf = buffer_factory.from_lines(HEADING_LINES)
    buffer_factory.move_cursor_away(buf)
    expect.truthy(plugin_session.render_until_settled(buf), 'settled')
    local details = extmark_reader.on_row(buf, 0)[1].details
    local first_chunk = details.virt_text[1]
    expect.truthy(
      vim.startswith(first_chunk[1], PLACEHOLDER),
      'placeholder cells'
    )
    expect.matches(first_chunk[2], IMAGE_HIGHLIGHT_PATTERN, 'image highlight')
    expect.equal(
      #details.virt_lines + 1,
      PRIMARY_HEADING_IMAGE_ROWS,
      'image rows'
    )
    for _, virt_line in ipairs(details.virt_lines) do
      expect.equal(#virt_line, 2, 'gutter plus placeholder chunks')
      expect.equal(virt_line[2][2], first_chunk[2], 'same image highlight')
    end
  end)

  spec.it('stops rasterizing once every heading is cached', function()
    local rasterized = stub.spy(glyph_run_rasterizer, 'draw')
    local buf = buffer_factory.from_lines(HEADING_LINES)
    buffer_factory.move_cursor_away(buf)
    expect.truthy(plugin_session.render_until_settled(buf), 'settled')
    local settled_raster_count = #rasterized
    local settled_payload_count = #payloads
    for _ = 1, SETTLED_RERENDERS do
      plugin_session.render(buf)
      plugin_session.wait_for_text_art()
    end
    expect.at_least(settled_raster_count, 1, 'renders rasterized')
    expect.equal(#rasterized, settled_raster_count, 'no new rasterization')
    expect.equal(#payloads, settled_payload_count, 'no new images transmitted')
  end)

  spec.it('deletes transmitted images when the cache is cleared', function()
    render_graphics_async(PRIMARY_HEADING)
    text_art_service.clear_cache()
    expect.truthy(has_payload(payloads, DELETE_MARKER), 'image deleted')
  end)
end)
