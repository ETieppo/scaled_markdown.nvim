---@class ImageHighlightGroupsProps
---@field DESCRIPTION string
---@field ICON string

---@class ImageHighlightProps
---@field GROUPS ImageHighlightGroupsProps
---@field DEFINITIONS HighlightDefinitionsProps

---@type ImageHighlightGroupsProps
local IMAGE_HIGHLIGHT_GROUPS = {
  DESCRIPTION = 'ScaledMarkdownImageDescription',
  ICON = 'ScaledMarkdownImageIcon',
}

---@type ImageHighlightProps
local IMAGE_HIGHLIGHT = {
  GROUPS = IMAGE_HIGHLIGHT_GROUPS,
  DEFINITIONS = {
    [IMAGE_HIGHLIGHT_GROUPS.DESCRIPTION] = {
      link = '@markup.link.label.markdown_inline',
    },
    [IMAGE_HIGHLIGHT_GROUPS.ICON] = { link = '@markup.link.markdown_inline' },
  },
}

return IMAGE_HIGHLIGHT
