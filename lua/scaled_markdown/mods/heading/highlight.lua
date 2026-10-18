


local MUTED_SOURCE_HIGHLIGHT = 'Comment'










local HEADING_HIGHLIGHT_GROUPS = {
   MUTED = 'ScaledMarkdownHeadingMuted',
}

local function build_definitions()
   local muted_source =
   vim.api.nvim_get_hl(0, { name = MUTED_SOURCE_HIGHLIGHT, link = false })
   return {
      [HEADING_HIGHLIGHT_GROUPS.MUTED] = { fg = muted_source.fg, italic = true },
   }
end

local HEADING_HIGHLIGHT = {
   GROUPS = HEADING_HIGHLIGHT_GROUPS,
   build_definitions = build_definitions,
}

return HEADING_HIGHLIGHT
