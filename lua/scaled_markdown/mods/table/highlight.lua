












local TABLE_HIGHLIGHT_GROUPS = {
   HEADER_CELL = 'ScaledMarkdownTableHeaderCell',
   BODY_CELL = 'ScaledMarkdownTableBodyCell',
}

local TABLE_HIGHLIGHT = {
   GROUPS = TABLE_HIGHLIGHT_GROUPS,
   DEFINITIONS = {
      [TABLE_HIGHLIGHT_GROUPS.HEADER_CELL] = { link = '@markup.heading.markdown' },
      [TABLE_HIGHLIGHT_GROUPS.BODY_CELL] = { link = 'Normal' },
   },
}

return TABLE_HIGHLIGHT
