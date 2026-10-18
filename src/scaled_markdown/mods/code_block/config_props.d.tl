local type ModConfigProps =
  require 'scaled_markdown.core.types.mod_config_props'

local record CodeBlockConfigProps is ModConfigProps
  min_width: integer
  horizontal_padding: integer
end

return CodeBlockConfigProps
