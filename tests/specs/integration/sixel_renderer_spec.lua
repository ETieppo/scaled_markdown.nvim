local RENDERER_ENUM = require 'scaled_markdown.core.enums.renderer_enum'
local buffer_factory = require 'helpers.buffer_factory'
local environment = require 'helpers.environment'
local expect = require 'harness.assertions'
local extmark_reader = require 'helpers.extmark_reader'
local graphics_image_registry =
  require 'scaled_markdown.core.text_art.graphics_image_registry'
local image_placement_registry =
  require 'scaled_markdown.core.render.image_placement_registry'
local plugin_session = require 'helpers.plugin_session'
local spec = require 'harness.spec'
local stub = require 'harness.stub'
local terminal_capability =
  require 'scaled_markdown.core.terminal.terminal_capability'
local terminal_cell_size =
  require 'scaled_markdown.core.terminal.terminal_cell_size'

local REQUIRED_FONT = 'FreeSans:bold'
local CELL_WIDTH = 10
local CELL_HEIGHT = 20
local PRIMARY_HEADING_ROWS = 3
local RASTER_PATTERN = '^\27P0;1;0q"1;1;(%d+);(%d+)'
---@type string[]
local HEADING_LINES = { '# Primary Heading', '', 'text' }
local NO_CURSOR_REVEAL = { cursor_line = false, visual_selection = false }

---@param buf integer
---@return ImagePlacementProps
local function single_placement(buf)
  local placements = image_placement_registry.list(buf)
  expect.equal(#placements, 1, 'one placement')
  return placements[1]
end

spec.describe('sixel renderer', function()
  spec.before_each(function()
    spec.skip_unless(
      environment.has_font(REQUIRED_FONT),
      environment.missing_font_reason(REQUIRED_FONT)
    )
    stub.replace(terminal_capability, 'protocol', function() return 'sixel' end)
    stub.replace(
      terminal_cell_size,
      'resolve',
      function() return { width = CELL_WIDTH, height = CELL_HEIGHT } end
    )
    stub.replace(vim.api, 'nvim_ui_send', function() end)
    plugin_session.start {
      renderer = RENDERER_ENUM.GRAPHICS,
      reveal = NO_CURSOR_REVEAL,
    }
  end)

  spec.it('reserves blank cells and registers the heading image', function()
    local buf = buffer_factory.from_lines(HEADING_LINES)
    expect.truthy(plugin_session.render_until_settled(buf), 'settled')
    local details = extmark_reader.on_row(buf, 0)[1].details
    expect.matches(details.virt_text[1][1], '^ +$', 'blank first row')
    expect.equal(details.virt_text[1][2], 'Normal', 'background cells')
    expect.equal(#details.virt_lines + 1, PRIMARY_HEADING_ROWS, 'image rows')
    local placement = single_placement(buf)
    expect.equal(placement.row, 0, 'heading row')
    expect.equal(placement.col, 0, 'heading column')
  end)

  spec.it('encodes images that exactly fill their cells', function()
    local buf = buffer_factory.from_lines(HEADING_LINES)
    plugin_session.render_until_settled(buf)
    local image =
      graphics_image_registry.positioned(single_placement(buf).image_id)
    ---@cast image -nil
    local width, height = image.payload:match(RASTER_PATTERN)
    expect.equal(tonumber(width), image.columns * CELL_WIDTH, 'pixel width')
    expect.equal(tonumber(height), image.rows * CELL_HEIGHT, 'pixel height')
    expect.equal(image.rows, PRIMARY_HEADING_ROWS, 'rows')
  end)

  spec.it('does not place images on revealed rows', function()
    plugin_session.start { renderer = RENDERER_ENUM.GRAPHICS }
    local buf = buffer_factory.from_lines(HEADING_LINES)
    plugin_session.render_until_settled(buf)
    expect.deep_equal(image_placement_registry.list(buf), {}, 'revealed')
  end)
end)
