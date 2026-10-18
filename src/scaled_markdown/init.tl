local type ConfigProps = require 'scaled_markdown.core.types.config_props'
local type ModProps = require 'scaled_markdown.core.types.mod_props'
local RENDERER_ENUM = require 'scaled_markdown.core.enums.renderer_enum'
local type RendererEnum = RENDERER_ENUM.RendererEnum
local buffer_attachment =
  require 'scaled_markdown.core.buffer.buffer_attachment'
local config_store = require 'scaled_markdown.core.config.config_store'
local plugin_setup = require 'scaled_markdown.core.setup.plugin_setup'

local record scaled_markdown
end

local MOD_PROPS_LIST <const>: {ModProps} = {
  require 'scaled_markdown.mods.heading',
  require 'scaled_markdown.mods.text',
  require 'scaled_markdown.mods.inline_code',
  --require 'scaled_markdown.mods.link',
  --require 'scaled_markdown.mods.link_reference',
  --require 'scaled_markdown.mods.image',
  --require 'scaled_markdown.mods.list',
  --require 'scaled_markdown.mods.checkbox',
  --require 'scaled_markdown.mods.quote',
  --require 'scaled_markdown.mods.code_block',
  --require 'scaled_markdown.mods.table',
  --require 'scaled_markdown.mods.thematic_break',
}

function scaled_markdown.setup(user_config?: ConfigProps)
  plugin_setup.run(user_config, MOD_PROPS_LIST)
end

function scaled_markdown.enable(buf?: integer) buffer_attachment.attach(buf) end
function scaled_markdown.disable(
  buf?: integer
) buffer_attachment.detach(buf) end
function scaled_markdown.toggle(buf?: integer) buffer_attachment.toggle(buf) end

function scaled_markdown.set_renderer(renderer: RendererEnum)
  config_store.set_renderer(renderer)
  buffer_attachment.refresh_all()
end

return scaled_markdown
