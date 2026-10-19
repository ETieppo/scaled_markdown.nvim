local MUTED_SOURCE_HIGHLIGHT = 'Comment'

---@class HeadingHighlightGroupsProps
---@field MUTED string

---@class HeadingHighlightProps
---@field GROUPS HeadingHighlightGroupsProps
---@field build_definitions fun(): HighlightDefinitionsProps

---@type HeadingHighlightGroupsProps
local HEADING_HIGHLIGHT_GROUPS = {
  MUTED = 'ScaledMarkdownHeadingMuted',
}

---@return HighlightDefinitionsProps
local function build_definitions()
  local muted_source =
    vim.api.nvim_get_hl(0, { name = MUTED_SOURCE_HIGHLIGHT, link = false })
  return {
    [HEADING_HIGHLIGHT_GROUPS.MUTED] = { fg = muted_source.fg, italic = true },
  }
end

---@type HeadingHighlightProps
local HEADING_HIGHLIGHT = {
  GROUPS = HEADING_HIGHLIGHT_GROUPS,
  build_definitions = build_definitions,
}

return HEADING_HIGHLIGHT
