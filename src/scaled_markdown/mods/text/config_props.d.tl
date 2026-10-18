local type ModConfigProps =
  require 'scaled_markdown.core.types.mod_config_props'

local record TextConfigProps is ModConfigProps
  conceal_delimiters: boolean
end

return TextConfigProps
