












local LINK_HIGHLIGHT_GROUPS = {
   TEXT = 'ScaledMarkdownLinkText',
   ICON = 'ScaledMarkdownLinkIcon',
}

local LINK_HIGHLIGHT = {
   GROUPS = LINK_HIGHLIGHT_GROUPS,
   DEFINITIONS = {
      [LINK_HIGHLIGHT_GROUPS.TEXT] = {
         link = '@markup.link.label.markdown_inline',
      },
      [LINK_HIGHLIGHT_GROUPS.ICON] = { link = '@markup.link.markdown_inline' },
   },
}

return LINK_HIGHLIGHT
