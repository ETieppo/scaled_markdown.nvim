












local CHECKBOX_HIGHLIGHT_GROUPS = {
   UNCHECKED = 'ScaledMarkdownCheckboxUnchecked',
   CHECKED = 'ScaledMarkdownCheckboxChecked',
}

local CHECKBOX_HIGHLIGHT = {
   GROUPS = CHECKBOX_HIGHLIGHT_GROUPS,
   DEFINITIONS = {
      [CHECKBOX_HIGHLIGHT_GROUPS.UNCHECKED] = {
         link = '@markup.list.unchecked.markdown',
      },
      [CHECKBOX_HIGHLIGHT_GROUPS.CHECKED] = {
         link = '@markup.list.checked.markdown',
      },
   },
}

return CHECKBOX_HIGHLIGHT
