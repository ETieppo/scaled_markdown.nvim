













local TEXT_HIGHLIGHT_GROUPS = {
   EMPHASIS = 'ScaledMarkdownTextEmphasis',
   STRONG_EMPHASIS = 'ScaledMarkdownTextStrongEmphasis',
   STRIKETHROUGH = 'ScaledMarkdownTextStrikethrough',
}

local TEXT_HIGHLIGHT = {
   GROUPS = TEXT_HIGHLIGHT_GROUPS,
   DEFINITIONS = {
      [TEXT_HIGHLIGHT_GROUPS.EMPHASIS] = { italic = true },
      [TEXT_HIGHLIGHT_GROUPS.STRONG_EMPHASIS] = { bold = true },
      [TEXT_HIGHLIGHT_GROUPS.STRIKETHROUGH] = { strikethrough = true },
   },
}

return TEXT_HIGHLIGHT
