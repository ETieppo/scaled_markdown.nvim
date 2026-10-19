local type ModConfigProps =
  require 'scaled_markdown.core.types.mod_config_props'

local record ImageConfigProps is ModConfigProps
  icon: string
end

return ImageConfigProps
