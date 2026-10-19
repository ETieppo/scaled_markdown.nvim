local type HighlightDefinitionsProps =
  require 'scaled_markdown.core.types.highlight_definitions_props'
local CALLOUT_TYPE_ENUM = require 'scaled_markdown.mods.quote.callout_type_enum'

local CALLOUT_HIGHLIGHT_LINKS <const>: {string: string} = {
  [CALLOUT_TYPE_ENUM.NOTE] = 'DiagnosticInfo',
  [CALLOUT_TYPE_ENUM.TIP] = 'DiagnosticOk',
  [CALLOUT_TYPE_ENUM.IMPORTANT] = 'DiagnosticHint',
  [CALLOUT_TYPE_ENUM.WARNING] = 'DiagnosticWarn',
  [CALLOUT_TYPE_ENUM.CAUTION] = 'DiagnosticError',
}

local record QuoteHighlightGroupsProps
  CALLOUT_BY_TYPE: {string: string}
end

local record QuoteHighlightProps
  GROUPS: QuoteHighlightGroupsProps
  DEFINITIONS: HighlightDefinitionsProps
end

local QUOTE_HIGHLIGHT_GROUPS <const>: QuoteHighlightGroupsProps = {
  CALLOUT_BY_TYPE = {},
}

local QUOTE_HIGHLIGHT_DEFINITIONS <const>: HighlightDefinitionsProps = {}

for callout_type, link_target in pairs(CALLOUT_HIGHLIGHT_LINKS) do
  local group_name = 'ScaledMarkdownQuoteCallout'
    .. callout_type:sub(1, 1)
    .. callout_type:sub(2):lower()
  QUOTE_HIGHLIGHT_GROUPS.CALLOUT_BY_TYPE[callout_type] = group_name
  QUOTE_HIGHLIGHT_DEFINITIONS[group_name] = { link = link_target }
end

local QUOTE_HIGHLIGHT <const>: QuoteHighlightProps = {
  GROUPS = QUOTE_HIGHLIGHT_GROUPS,
  DEFINITIONS = QUOTE_HIGHLIGHT_DEFINITIONS,
}

return QUOTE_HIGHLIGHT
