local type HighlightDefinitionsProps =
  require 'scaled_markdown.core.types.highlight_definitions_props'

local record ListHighlightGroupsProps
  BULLET: string
  ORDERED: string
end

local record ListHighlightProps
  GROUPS: ListHighlightGroupsProps
  DEFINITIONS: HighlightDefinitionsProps
end

local LIST_HIGHLIGHT_GROUPS <const>: ListHighlightGroupsProps = {
  BULLET = 'ScaledMarkdownListBullet',
  ORDERED = 'ScaledMarkdownListOrdered',
}

local LIST_HIGHLIGHT <const>: ListHighlightProps = {
  GROUPS = LIST_HIGHLIGHT_GROUPS,
  DEFINITIONS = {
    [LIST_HIGHLIGHT_GROUPS.BULLET] = { link = '@markup.list.markdown' },
    [LIST_HIGHLIGHT_GROUPS.ORDERED] = { link = '@markup.list.markdown' },
  },
}

return LIST_HIGHLIGHT
