local RendererEnum = require 'scaled_markdown.core.enums.renderer_enum'
local text_art_service =
  require 'scaled_markdown.core.text_art.text_art_service'
local buffer_attachment =
  require 'scaled_markdown.core.buffer.buffer_attachment'
local config_store = require 'scaled_markdown.core.config.config_store'

local subcommand_handlers = {}

subcommand_handlers.enable = {
  run = function() buffer_attachment.attach(0) end,
}

subcommand_handlers.disable = {
  run = function() buffer_attachment.detach(0) end,
}

subcommand_handlers.toggle = {
  run = function() buffer_attachment.toggle(0) end,
}

subcommand_handlers.refresh = {
  run = function()
    text_art_service.clear_cache()
    buffer_attachment.refresh_all()
  end,
}

subcommand_handlers.renderer = {
  run = function(arguments)
    local renderer = arguments[1]
    if not config_store.is_valid_renderer(renderer) then
      error(('unknown renderer: %s'):format(tostring(renderer)))
    end

    config_store.set_renderer(renderer)
    text_art_service.clear_cache()
    buffer_attachment.refresh_all()
  end,

  complete = function() return vim.tbl_values(RendererEnum) end,
}

return subcommand_handlers
