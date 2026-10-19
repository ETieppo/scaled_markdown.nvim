local type HighlightDefinitionsProps =
  require 'scaled_markdown.core.types.highlight_definitions_props'

local record TableHighlightGroupsProps
  HEADER_CELL: string
  BODY_CELL: string
end

local record TableHighlightProps
  GROUPS: TableHighlightGroupsProps
  DEFINITIONS: HighlightDefinitionsProps
end

local TABLE_HIGHLIGHT_GROUPS <const>: TableHighlightGroupsProps = {
  HEADER_CELL = 'ScaledMarkdownTableHeaderCell',
  BODY_CELL = 'ScaledMarkdownTableBodyCell',
}

local TABLE_HIGHLIGHT <const>: TableHighlightProps = {
  GROUPS = TABLE_HIGHLIGHT_GROUPS,
  DEFINITIONS = {
    [TABLE_HIGHLIGHT_GROUPS.HEADER_CELL] = { link = '@markup.heading.markdown' },
    [TABLE_HIGHLIGHT_GROUPS.BODY_CELL] = { link = 'Normal' },
  },
}

return TABLE_HIGHLIGHT
