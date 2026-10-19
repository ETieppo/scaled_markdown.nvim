---@class InlineCodeHighlightGroupsProps
---@field CODE_SPAN string

---@class InlineCodeHighlightProps
---@field GROUPS InlineCodeHighlightGroupsProps
---@field DEFINITIONS HighlightDefinitionsProps

---@type InlineCodeHighlightGroupsProps
local INLINE_CODE_HIGHLIGHT_GROUPS = {
  CODE_SPAN = 'ScaledMarkdownInlineCode',
}

---@type InlineCodeHighlightProps
local INLINE_CODE_HIGHLIGHT = {
  GROUPS = INLINE_CODE_HIGHLIGHT_GROUPS,
  DEFINITIONS = {
    [INLINE_CODE_HIGHLIGHT_GROUPS.CODE_SPAN] = {
      link = '@markup.raw.markdown_inline',
    },
  },
}

return INLINE_CODE_HIGHLIGHT
