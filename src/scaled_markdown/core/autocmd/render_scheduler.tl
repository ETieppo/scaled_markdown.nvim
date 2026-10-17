local CORE_CONSTANTS = require 'scaled_markdown.core.constants'
local render_pipeline = require 'scaled_markdown.core.render.render_pipeline'

local record render_scheduler
end

local timers_by_buffer: {integer: vim.TimerProps} = {}

function render_scheduler.cancel(buf: integer)
  local timer = timers_by_buffer[buf]
  timers_by_buffer[buf] = nil
  if timer and not timer:is_closing() then
    timer:stop()
    timer:close()
  end
end

function render_scheduler.schedule(buf: integer)
  render_scheduler.cancel(buf)
  local timer = vim.uv.new_timer()

  timers_by_buffer[buf] = timer
  timer:start(CORE_CONSTANTS.RENDER_DEBOUNCE_MS, 0, function()
    vim.schedule(function()
      if timers_by_buffer[buf] == timer then
        render_scheduler.cancel(buf)
        render_pipeline.render(buf)
      end
    end)
  end)
end

return render_scheduler
