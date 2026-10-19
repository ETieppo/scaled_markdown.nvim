local type QuoteConfigProps = require 'scaled_markdown.mods.quote.config_props'

local record CalloutMatchProps
  props: QuoteConfigProps.CalloutProps
  highlight: string
  start_col: integer
  end_col: integer
end

return CalloutMatchProps
