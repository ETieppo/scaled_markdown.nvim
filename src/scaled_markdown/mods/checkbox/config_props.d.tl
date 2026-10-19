local type ModConfigProps =
  require 'scaled_markdown.core.types.mod_config_props'

local record CheckboxConfigProps is ModConfigProps
  unchecked_icon: string
  checked_icon: string
end

return CheckboxConfigProps
