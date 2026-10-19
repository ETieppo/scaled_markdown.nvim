---@class ListHighlightGroupsProps
---@field BULLET string
---@field ORDERED string

---@class ListHighlightProps
---@field GROUPS ListHighlightGroupsProps
---@field DEFINITIONS HighlightDefinitionsProps

---@type ListHighlightGroupsProps
local LIST_HIGHLIGHT_GROUPS = {
  BULLET = 'ScaledMarkdownListBullet',
  ORDERED = 'ScaledMarkdownListOrdered',
}

---@type ListHighlightProps
local LIST_HIGHLIGHT = {
  GROUPS = LIST_HIGHLIGHT_GROUPS,
  DEFINITIONS = {
    [LIST_HIGHLIGHT_GROUPS.BULLET] = { link = '@markup.list.markdown' },
    [LIST_HIGHLIGHT_GROUPS.ORDERED] = { link = '@markup.list.markdown' },
  },
}

return LIST_HIGHLIGHT
