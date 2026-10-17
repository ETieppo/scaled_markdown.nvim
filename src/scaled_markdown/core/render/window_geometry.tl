local record window_geometry
end

function window_geometry.text_offset(win: integer): integer
  local window_info = vim.fn.getwininfo(win)[1]
  return window_info and window_info.textoff or 0
end

function window_geometry.text_area_width(win: integer): integer
  return math.max(
    1,
    vim.api.nvim_win_get_width(win) - window_geometry.text_offset(win)
  )
end

return window_geometry
