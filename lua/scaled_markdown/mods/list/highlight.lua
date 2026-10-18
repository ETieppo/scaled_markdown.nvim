












local LIST_HIGHLIGHT_GROUPS = {
   BULLET = 'ScaledMarkdownListBullet',
   ORDERED = 'ScaledMarkdownListOrdered',
}

local LIST_HIGHLIGHT = {
   GROUPS = LIST_HIGHLIGHT_GROUPS,
   DEFINITIONS = {
      [LIST_HIGHLIGHT_GROUPS.BULLET] = { link = '@markup.list.markdown' },
      [LIST_HIGHLIGHT_GROUPS.ORDERED] = { link = '@markup.list.markdown' },
   },
}

return LIST_HIGHLIGHT
