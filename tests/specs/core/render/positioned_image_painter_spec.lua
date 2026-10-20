local buffer_factory = require 'helpers.buffer_factory'
local expect = require 'harness.assertions'
local graphics_image_registry =
  require 'scaled_markdown.core.text_art.graphics_image_registry'
local image_placement_registry =
  require 'scaled_markdown.core.render.image_placement_registry'
local plugin_session = require 'helpers.plugin_session'
local positioned_image_painter =
  require 'scaled_markdown.core.render.positioned_image_painter'
local screen_image_geometry =
  require 'scaled_markdown.core.render.screen_image_geometry'
local spec = require 'harness.spec'
local stub = require 'harness.stub'
local terminal_capability =
  require 'scaled_markdown.core.terminal.terminal_capability'

local PAYLOAD = '\27Pq#0~\27\\'
local IMAGE_COLUMNS = 4
local IMAGE_ROWS = 2

---@param line_count integer
---@return string[]
local function build_lines(line_count)
  ---@type string[]
  local lines = {}
  for index = 1, line_count do
    lines[index] = 'line ' .. index
  end
  return lines
end

---@param row integer
---@return integer, integer
local function place_image(row)
  local buf = vim.api.nvim_get_current_buf()
  local image_id = graphics_image_registry.register_positioned(
    PAYLOAD,
    IMAGE_COLUMNS,
    IMAGE_ROWS
  )
  image_placement_registry.add(buf, { row = row, col = 0, image_id = image_id })
  return buf, image_id
end

---@return string[]
local function capture_terminal_output()
  ---@type string[]
  local sent = {}
  stub.replace(
    vim.api,
    'nvim_ui_send',
    ---@param data string
    function(data) sent[#sent + 1] = data end
  )
  return sent
end

spec.describe('positioned image painter', function()
  spec.before_each(function()
    plugin_session.start { renderer = 'plain' }
    buffer_factory.from_lines(build_lines(60))
    vim.cmd.only()
    vim.wo.number = false
    vim.wo.signcolumn = 'no'
  end)

  spec.it('finds the screen cell of a visible placement', function()
    local _, image_id = place_image(2)
    expect.deep_equal(
      screen_image_geometry.collect(),
      { { screen_row = 3, screen_col = 1, image_id = image_id } },
      'screen position'
    )
  end)

  spec.it('skips placements scrolled out of view', function()
    place_image(50)
    expect.deep_equal(screen_image_geometry.collect(), {}, 'off screen')
  end)

  spec.it('skips placements that would reach the last screen rows', function()
    local last_text_row = vim.fn.line 'w$' - 1
    place_image(last_text_row)
    expect.deep_equal(screen_image_geometry.collect(), {}, 'clipped')
  end)

  spec.it('skips placements covered by a floating window', function()
    place_image(2)
    local float_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_open_win(float_buf, false, {
      relative = 'editor',
      row = 2,
      col = 2,
      width = 10,
      height = 3,
    })
    expect.deep_equal(screen_image_geometry.collect(), {}, 'covered')
  end)

  spec.it(
    'moves the cursor to each image inside synchronized output',
    function()
      local _, image_id = place_image(2)
      expect.equal(
        positioned_image_painter.build_output {
          { screen_row = 3, screen_col = 5, image_id = image_id },
        },
        '\27[?2026h\0277\27[3;5H' .. PAYLOAD .. '\0278\27[?2026l',
        'output'
      )
    end
  )

  spec.it('paints only when sixel is the active protocol', function()
    local sent = capture_terminal_output()
    place_image(2)
    stub.replace(terminal_capability, 'protocol', function() return 'none' end)
    positioned_image_painter.paint()
    expect.equal(#sent, 0, 'nothing painted')
    stub.replace(terminal_capability, 'protocol', function() return 'sixel' end)
    positioned_image_painter.paint()
    expect.equal(#sent, 1, 'painted')
    expect.matches(sent[1], '\27%[3;1H', 'cursor move')
  end)

  spec.it(
    'repaints only when placements change or a repaint is requested',
    function()
      local sent = capture_terminal_output()
      stub.replace(
        terminal_capability,
        'protocol',
        function() return 'sixel' end
      )
      place_image(2)
      positioned_image_painter.paint()
      positioned_image_painter.paint()
      expect.equal(#sent, 1, 'unchanged screen not repainted')
      positioned_image_painter.request_repaint()
      positioned_image_painter.paint()
      expect.equal(#sent, 2, 'requested repaint')
    end
  )
end)
