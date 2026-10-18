local type HighlightDefinitionsProps =
  require 'scaled_markdown.core.types.highlight_definitions_props'

local record LinkHighlightGroupsProps
  TEXT: string
  ICON: string
end

local record LinkHighlightProps
  GROUPS: LinkHighlightGroupsProps
  DEFINITIONS: HighlightDefinitionsProps
end

local LINK_HIGHLIGHT_GROUPS <const>: LinkHighlightGroupsProps = {
  TEXT = 'ScaledMarkdownLinkText',
  ICON = 'ScaledMarkdownLinkIcon',
}

local LINK_HIGHLIGHT <const>: LinkHighlightProps = {
  GROUPS = LINK_HIGHLIGHT_GROUPS,
  DEFINITIONS = {
    [LINK_HIGHLIGHT_GROUPS.TEXT] = {
      link = '@markup.link.label.markdown_inline',
    },
    [LINK_HIGHLIGHT_GROUPS.ICON] = { link = '@markup.link.markdown_inline' },
  },
}

return LINK_HIGHLIGHT
