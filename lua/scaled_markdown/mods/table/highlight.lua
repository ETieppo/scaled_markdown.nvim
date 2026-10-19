---@class TableHighlightGroupsProps
---@field HEADER_CELL string
---@field BODY_CELL string

---@class TableHighlightProps
---@field GROUPS TableHighlightGroupsProps
---@field DEFINITIONS HighlightDefinitionsProps

---@type TableHighlightGroupsProps
local TABLE_HIGHLIGHT_GROUPS = {
  HEADER_CELL = 'ScaledMarkdownTableHeaderCell',
  BODY_CELL = 'ScaledMarkdownTableBodyCell',
}

---@type TableHighlightProps
local TABLE_HIGHLIGHT = {
  GROUPS = TABLE_HIGHLIGHT_GROUPS,
  DEFINITIONS = {
    [TABLE_HIGHLIGHT_GROUPS.HEADER_CELL] = { link = '@markup.heading.markdown' },
    [TABLE_HIGHLIGHT_GROUPS.BODY_CELL] = { link = 'Normal' },
  },
}

return TABLE_HIGHLIGHT
