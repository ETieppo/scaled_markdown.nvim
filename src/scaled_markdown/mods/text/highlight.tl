local type HighlightDefinitionsProps =
  require 'scaled_markdown.core.types.highlight_definitions_props'

local record TextHighlightGroupsProps
  EMPHASIS: string
  STRONG_EMPHASIS: string
  STRIKETHROUGH: string
end

local record TextHighlightProps
  GROUPS: TextHighlightGroupsProps
  DEFINITIONS: HighlightDefinitionsProps
end

local TEXT_HIGHLIGHT_GROUPS <const>: TextHighlightGroupsProps = {
  EMPHASIS = 'ScaledMarkdownTextEmphasis',
  STRONG_EMPHASIS = 'ScaledMarkdownTextStrongEmphasis',
  STRIKETHROUGH = 'ScaledMarkdownTextStrikethrough',
}

local TEXT_HIGHLIGHT <const>: TextHighlightProps = {
  GROUPS = TEXT_HIGHLIGHT_GROUPS,
  DEFINITIONS = {
    [TEXT_HIGHLIGHT_GROUPS.EMPHASIS] = { italic = true },
    [TEXT_HIGHLIGHT_GROUPS.STRONG_EMPHASIS] = { bold = true },
    [TEXT_HIGHLIGHT_GROUPS.STRIKETHROUGH] = { strikethrough = true },
  },
}

return TEXT_HIGHLIGHT
