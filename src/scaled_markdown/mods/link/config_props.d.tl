local type ModConfigProps =
  require 'scaled_markdown.core.types.mod_config_props'

local record LinkConfigProps is ModConfigProps
  icon: string
  autolink_icon: string
end

return LinkConfigProps
