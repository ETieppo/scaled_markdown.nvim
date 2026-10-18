local type HighlightDefinitionsProps =
  require 'scaled_markdown.core.types.highlight_definitions_props'

local MUTED_SOURCE_HIGHLIGHT <const> = 'Comment'

local record HeadingHighlightGroupsProps
  MUTED: string
end

local record HeadingHighlightProps
  GROUPS: HeadingHighlightGroupsProps
  build_definitions: function(): HighlightDefinitionsProps
end

local HEADING_HIGHLIGHT_GROUPS <const>: HeadingHighlightGroupsProps = {
  MUTED = 'ScaledMarkdownHeadingMuted',
}

local function build_definitions(): HighlightDefinitionsProps
  local muted_source =
    vim.api.nvim_get_hl(0, { name = MUTED_SOURCE_HIGHLIGHT, link = false })
  return {
    [HEADING_HIGHLIGHT_GROUPS.MUTED] = { fg = muted_source.fg, italic = true },
  }
end

local HEADING_HIGHLIGHT <const>: HeadingHighlightProps = {
  GROUPS = HEADING_HIGHLIGHT_GROUPS,
  build_definitions = build_definitions,
}

return HEADING_HIGHLIGHT
