local type ExtmarkWriterProps =
  require 'scaled_markdown.core.types.extmark_writer_props'
local type ModConfigProps =
  require 'scaled_markdown.core.types.mod_config_props'

local record RenderContextProps<C is ModConfigProps>
  buf: integer
  win: integer
  writer: ExtmarkWriterProps
  text_area_width: integer
  line_at: function(row: integer): string
  mod_config: C
end

return RenderContextProps
