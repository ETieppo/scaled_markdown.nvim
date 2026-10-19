local type ModConfigProps =
  require 'scaled_markdown.core.types.mod_config_props'

local record QuoteConfigProps is ModConfigProps
  record CalloutProps
    icon: string
    title: string
  end

  bar: string
  callouts: {string: CalloutProps}
end

return QuoteConfigProps
