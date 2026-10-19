local type HighlightDefinitionsProps =
  require 'scaled_markdown.core.types.highlight_definitions_props'

local record ImageHighlightGroupsProps
  DESCRIPTION: string
  ICON: string
end

local record ImageHighlightProps
  GROUPS: ImageHighlightGroupsProps
  DEFINITIONS: HighlightDefinitionsProps
end

local IMAGE_HIGHLIGHT_GROUPS <const>: ImageHighlightGroupsProps = {
  DESCRIPTION = 'ScaledMarkdownImageDescription',
  ICON = 'ScaledMarkdownImageIcon',
}

local IMAGE_HIGHLIGHT <const>: ImageHighlightProps = {
  GROUPS = IMAGE_HIGHLIGHT_GROUPS,
  DEFINITIONS = {
    [IMAGE_HIGHLIGHT_GROUPS.DESCRIPTION] = {
      link = '@markup.link.label.markdown_inline',
    },
    [IMAGE_HIGHLIGHT_GROUPS.ICON] = { link = '@markup.link.markdown_inline' },
  },
}

return IMAGE_HIGHLIGHT
