local type ModConfigProps =
  require 'scaled_markdown.core.types.mod_config_props'

local record TableConfigProps is ModConfigProps
  cell_padding: integer
  min_column_width: integer
end

return TableConfigProps
