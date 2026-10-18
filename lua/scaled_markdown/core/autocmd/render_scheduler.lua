local CORE_CONSTANTS = require('scaled_markdown.core.constants')
local render_pipeline = require('scaled_markdown.core.render.render_pipeline')

local render_scheduler = {}


local timers_by_buffer = {}

function render_scheduler.cancel(buf)
   local timer = timers_by_buffer[buf]
   timers_by_buffer[buf] = nil
   if timer and not timer:is_closing() then
      timer:stop()
      timer:close()
   end
end

function render_scheduler.schedule(buf)
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
