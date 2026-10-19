local HEX_COLOR_FORMAT = '#%06x'

---@class theme_color_resolver
local theme_color_resolver = {}

---@param group_names string[]
---@return string?
function theme_color_resolver.resolve_foreground(group_names)
  for _, group_name in ipairs(group_names) do
    local highlight =
      vim.api.nvim_get_hl(0, { name = group_name, link = false })
    if highlight.fg then return HEX_COLOR_FORMAT:format(highlight.fg) end
  end
  return nil
end

---@param group_name string
---@return string?
function theme_color_resolver.resolve_background(group_name)
  local highlight = vim.api.nvim_get_hl(0, { name = group_name, link = false })
  return highlight.bg and HEX_COLOR_FORMAT:format(highlight.bg) or nil
end

return theme_color_resolver
