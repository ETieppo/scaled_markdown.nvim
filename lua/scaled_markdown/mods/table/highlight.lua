---@class TableHighlightGroupsProps
---@field HEADER_CELL string
---@field BODY_CELL string
---@field INLINE_CODE string

---@class TableHighlightProps
---@field GROUPS TableHighlightGroupsProps
---@field DEFINITIONS HighlightDefinitionsProps

---@type TableHighlightGroupsProps
local TABLE_HIGHLIGHT_GROUPS = {
  HEADER_CELL = 'ScaledMarkdownTableHeaderCell',
  BODY_CELL = 'ScaledMarkdownTableBodyCell',
  INLINE_CODE = 'ScaledMarkdownTableInlineCode',
}

---@type TableHighlightProps
local TABLE_HIGHLIGHT = {
  GROUPS = TABLE_HIGHLIGHT_GROUPS,
  DEFINITIONS = {
    [TABLE_HIGHLIGHT_GROUPS.HEADER_CELL] = { link = '@markup.heading.markdown' },
    [TABLE_HIGHLIGHT_GROUPS.BODY_CELL] = { link = 'Normal' },
    [TABLE_HIGHLIGHT_GROUPS.INLINE_CODE] = {
      link = '@markup.raw.markdown_inline',
    },
  },
}

return TABLE_HIGHLIGHT
