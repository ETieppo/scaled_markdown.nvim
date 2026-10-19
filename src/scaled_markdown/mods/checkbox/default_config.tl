local type CheckboxConfigProps =
  require 'scaled_markdown.mods.checkbox.config_props'

local DEFAULT_CHECKBOX_CONFIG <const>: CheckboxConfigProps = {
  unchecked_icon = '☐',
  checked_icon = '■',
}

return DEFAULT_CHECKBOX_CONFIG
