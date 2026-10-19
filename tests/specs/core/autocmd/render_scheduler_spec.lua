local expect = require 'harness.assertions'
local spec = require 'harness.spec'
local stub = require 'harness.stub'
local buffer_factory = require 'helpers.buffer_factory'
local plugin_session = require 'helpers.plugin_session'
local render_scheduler = require 'scaled_markdown.core.autocmd.render_scheduler'
local CORE_CONSTANTS = require 'scaled_markdown.core.constants'
local render_pipeline = require 'scaled_markdown.core.render.render_pipeline'
local BURST_SIZE = 10
local SETTLE_MS = CORE_CONSTANTS.RENDER_DEBOUNCE_MS * 8
local UNSCHEDULED_BUFFER = 424242

local function let_debounce_settle()
  vim.wait(SETTLE_MS, function() return false end)
end

spec.describe('render_scheduler', function()
  spec.before_each(function() plugin_session.start() end)

  spec.it('collapses a burst of schedules into a single render', function()
    local buf = buffer_factory.from_lines { 'a' }
    local calls = stub.spy(render_pipeline, 'render')

    for _ = 1, BURST_SIZE do
      render_scheduler.schedule(buf)
    end

    let_debounce_settle()
    expect.equal(#calls, 1, 'single render')
    expect.equal(calls[1][1], buf, 'rendered buffer')
  end)

  spec.it('does not render a cancelled schedule', function()
    local buf = buffer_factory.from_lines { 'a' }
    local calls = stub.spy(render_pipeline, 'render')

    render_scheduler.schedule(buf)
    render_scheduler.cancel(buf)
    let_debounce_settle()
    expect.equal(#calls, 0, 'no render')
  end)

  spec.it('debounces buffers independently', function()
    local first_buf = buffer_factory.from_lines { 'a' }
    local second_buf = buffer_factory.from_lines { 'b' }
    local calls = stub.spy(render_pipeline, 'render')
    render_scheduler.schedule(first_buf)
    render_scheduler.schedule(second_buf)
    let_debounce_settle()

    ---@type integer[]
    local rendered = {}
    for _, call in ipairs(calls) do
      rendered[#rendered + 1] = call[1]
    end

    table.sort(rendered)
    expect.deep_equal(rendered, { first_buf, second_buf }, 'both rendered')
  end)

  spec.it('tolerates cancelling buffers without a schedule', function()
    expect.succeeds(
      function() render_scheduler.cancel(UNSCHEDULED_BUFFER) end,
      'cancel'
    )
  end)
end)
