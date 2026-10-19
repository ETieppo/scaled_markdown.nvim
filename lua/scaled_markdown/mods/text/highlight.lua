---@class TextHighlightGroupsProps
---@field EMPHASIS string
---@field STRONG_EMPHASIS string
---@field STRIKETHROUGH string

---@class TextHighlightProps
---@field GROUPS TextHighlightGroupsProps
---@field DEFINITIONS HighlightDefinitionsProps

---@type TextHighlightGroupsProps
local TEXT_HIGHLIGHT_GROUPS = {
  EMPHASIS = 'ScaledMarkdownTextEmphasis',
  STRONG_EMPHASIS = 'ScaledMarkdownTextStrongEmphasis',
  STRIKETHROUGH = 'ScaledMarkdownTextStrikethrough',
}

---@type TextHighlightProps
local TEXT_HIGHLIGHT = {
  GROUPS = TEXT_HIGHLIGHT_GROUPS,
  DEFINITIONS = {
    [TEXT_HIGHLIGHT_GROUPS.EMPHASIS] = { italic = true },
    [TEXT_HIGHLIGHT_GROUPS.STRONG_EMPHASIS] = { bold = true },
    [TEXT_HIGHLIGHT_GROUPS.STRIKETHROUGH] = { strikethrough = true },
  },
}

return TEXT_HIGHLIGHT
