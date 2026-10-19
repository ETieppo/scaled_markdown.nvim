local type ModConfigProps =
  require 'scaled_markdown.core.types.mod_config_props'

local record ThematicBreakConfigProps is ModConfigProps
  character: string
end

return ThematicBreakConfigProps
