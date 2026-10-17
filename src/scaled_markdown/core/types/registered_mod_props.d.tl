local type ModProps = require 'scaled_markdown.core.types.mod_props'

local record RegisteredModProps
  props: ModProps
  query: vim.QueryProps
end

return RegisteredModProps
