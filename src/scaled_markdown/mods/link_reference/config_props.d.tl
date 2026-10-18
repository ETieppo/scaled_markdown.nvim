local type ModConfigProps =
  require 'scaled_markdown.core.types.mod_config_props'

local record LinkReferenceConfigProps is ModConfigProps
  icon: string
end

return LinkReferenceConfigProps
