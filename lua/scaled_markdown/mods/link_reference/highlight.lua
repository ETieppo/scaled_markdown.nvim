---@class LinkReferenceHighlightGroupsProps
---@field ICON string
---@field LABEL string
---@field DESTINATION string
---@field TITLE string

---@class LinkReferenceHighlightProps
---@field GROUPS LinkReferenceHighlightGroupsProps
---@field DEFINITIONS HighlightDefinitionsProps

---@type LinkReferenceHighlightGroupsProps
local LINK_REFERENCE_HIGHLIGHT_GROUPS = {
  ICON = 'ScaledMarkdownLinkReferenceIcon',
  LABEL = 'ScaledMarkdownLinkReferenceLabel',
  DESTINATION = 'ScaledMarkdownLinkReferenceDestination',
  TITLE = 'ScaledMarkdownLinkReferenceTitle',
}

---@type LinkReferenceHighlightProps
local LINK_REFERENCE_HIGHLIGHT = {
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
