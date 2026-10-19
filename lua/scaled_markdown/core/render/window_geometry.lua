---@class window_geometry
local window_geometry = {}

---@param win integer
---@return integer
function window_geometry.text_offset(win)
  local window_info = vim.fn.getwininfo(win)[1]
  return window_info and window_info.textoff or 0
end

---@param win integer
---@return integer
function window_geometry.text_area_width(win)
  return math.max(
    1,
    vim.api.nvim_win_get_width(win) - window_geometry.text_offset(win)
  )
end

return window_geometry
