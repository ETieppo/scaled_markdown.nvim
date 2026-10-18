local type HighlightDefinitionsProps =
  require 'scaled_markdown.core.types.highlight_definitions_props'

local record LinkReferenceHighlightGroupsProps
  ICON: string
  LABEL: string
  DESTINATION: string
  TITLE: string
end

local record LinkReferenceHighlightProps
  GROUPS: LinkReferenceHighlightGroupsProps
  DEFINITIONS: HighlightDefinitionsProps
end

local LINK_REFERENCE_HIGHLIGHT_GROUPS <const>: LinkReferenceHighlightGroupsProps = {
  ICON = 'ScaledMarkdownLinkReferenceIcon',
  LABEL = 'ScaledMarkdownLinkReferenceLabel',
  DESTINATION = 'ScaledMarkdownLinkReferenceDestination',
  TITLE = 'ScaledMarkdownLinkReferenceTitle',
}

local LINK_REFERENCE_HIGHLIGHT <const>: LinkReferenceHighlightProps = {
  GROUPS = LINK_REFERENCE_HIGHLIGHT_GROUPS,
  DEFINITIONS = {
    [LINK_REFERENCE_HIGHLIGHT_GROUPS.ICON] = {
      link = '@markup.link.markdown_inline',
    },
    [LINK_REFERENCE_HIGHLIGHT_GROUPS.LABEL] = {
      link = '@markup.link.label.markdown_inline',
    },
    [LINK_REFERENCE_HIGHLIGHT_GROUPS.DESTINATION] = {
      link = '@markup.link.url.markdown_inline',
    },
    [LINK_REFERENCE_HIGHLIGHT_GROUPS.TITLE] = { link = 'Comment' },
  },
}

return LINK_REFERENCE_HIGHLIGHT
