local type ModConfigProps =
  require 'scaled_markdown.core.types.mod_config_props'

local record InlineCodeConfigProps is ModConfigProps
  delimiter_replacement: string
end

return InlineCodeConfigProps
