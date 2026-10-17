local buffer_attachment =
  require 'scaled_markdown.core.buffer.buffer_attachment'
local scaled_markdown = {}

local MOD_PROPS_LIST = {
}

function scaled_markdown.enable(buf) buffer_attachment.attach(buf) end
function scaled_markdown.disable(buf) buffer_attachment.detach(buf) end
function scaled_markdown.toggle(buf) buffer_attachment.toggle(buf) end

function scaled_markdown.set_renderer(renderer)
  buffer_attachment.refresh_all()
end

return scaled_markdown
