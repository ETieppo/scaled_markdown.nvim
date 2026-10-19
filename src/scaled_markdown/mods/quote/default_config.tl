local type QuoteConfigProps = require 'scaled_markdown.mods.quote.config_props'
local CALLOUT_TYPE_ENUM = require 'scaled_markdown.mods.quote.callout_type_enum'

local DEFAULT_QUOTE_CONFIG <const>: QuoteConfigProps = {
  bar = '▌',
  callouts = {
    [CALLOUT_TYPE_ENUM.NOTE] = { icon = 'ⓘ ', title = 'Note' },
    [CALLOUT_TYPE_ENUM.TIP] = { icon = '✦ ', title = 'Tip' },
    [CALLOUT_TYPE_ENUM.IMPORTANT] = { icon = '❖ ', title = 'Important' },
    [CALLOUT_TYPE_ENUM.WARNING] = { icon = '▲ ', title = 'Warning' },
    [CALLOUT_TYPE_ENUM.CAUTION] = { icon = '✖ ', title = 'Caution' },
  },
}

return DEFAULT_QUOTE_CONFIG
