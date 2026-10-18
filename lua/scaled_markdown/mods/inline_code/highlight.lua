











local INLINE_CODE_HIGHLIGHT_GROUPS = {
   CODE_SPAN = 'ScaledMarkdownInlineCode',
}

local INLINE_CODE_HIGHLIGHT = {
   GROUPS = INLINE_CODE_HIGHLIGHT_GROUPS,
   DEFINITIONS = {
      [INLINE_CODE_HIGHLIGHT_GROUPS.CODE_SPAN] = {
         link = '@markup.raw.markdown_inline',
      },
   },
}

return INLINE_CODE_HIGHLIGHT
