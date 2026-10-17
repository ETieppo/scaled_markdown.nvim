local buffer_attachment =
  require 'scaled_markdown.core.buffer.buffer_attachment'
local config_store = require 'scaled_markdown.core.config.config_store'
local plugin_setup = require 'scaled_markdown.core.setup.plugin_setup'
local scaled_markdown = {}

local MOD_PROPS_LIST = {
}


function scaled_markdown.setup(user_config)
  plugin_setup.run(user_config, MOD_PROPS_LIST)
end

function scaled_markdown.enable(buf) buffer_attachment.attach(buf) end
function scaled_markdown.disable(buf) buffer_attachment.detach(buf) end
function scaled_markdown.toggle(buf) buffer_attachment.toggle(buf) end

function scaled_markdown.set_renderer(renderer)
  config_store.set_renderer(renderer)
  buffer_attachment.refresh_all()
end

return scaled_markdown
