local type HighlightDefinitionsProps =
  require 'scaled_markdown.core.types.highlight_definitions_props'

local record InlineCodeHighlightGroupsProps
  CODE_SPAN: string
end

local record InlineCodeHighlightProps
  GROUPS: InlineCodeHighlightGroupsProps
  DEFINITIONS: HighlightDefinitionsProps
end

local INLINE_CODE_HIGHLIGHT_GROUPS <const>: InlineCodeHighlightGroupsProps = {
  CODE_SPAN = 'ScaledMarkdownInlineCode',
}

local INLINE_CODE_HIGHLIGHT <const>: InlineCodeHighlightProps = {
  GROUPS = INLINE_CODE_HIGHLIGHT_GROUPS,
  DEFINITIONS = {
    [INLINE_CODE_HIGHLIGHT_GROUPS.CODE_SPAN] = {
      link = '@markup.raw.markdown_inline',
    },
  },
}

return INLINE_CODE_HIGHLIGHT
