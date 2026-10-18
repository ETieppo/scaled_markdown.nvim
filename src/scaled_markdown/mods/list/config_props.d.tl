local type ModConfigProps =
  require 'scaled_markdown.core.types.mod_config_props'

local record ListConfigProps is ModConfigProps
  bullets: {string}
end

return ListConfigProps
