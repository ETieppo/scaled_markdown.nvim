












local IMAGE_HIGHLIGHT_GROUPS = {
   DESCRIPTION = 'ScaledMarkdownImageDescription',
   ICON = 'ScaledMarkdownImageIcon',
}

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
