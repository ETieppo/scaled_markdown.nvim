local buffer_state_store =
  require 'scaled_markdown.core.buffer.buffer_state_store'
local graphics_image_registry =
  require 'scaled_markdown.core.text_art.graphics_image_registry'
local image_placement_registry =
  require 'scaled_markdown.core.render.image_placement_registry'

local NO_BORDER = 'none'
local BORDER_WIDTH = 1
local LAST_ROW_MARGIN = 1

---@class screen_image_geometry
local screen_image_geometry = {}

---@param first ScreenRectProps
---@param second ScreenRectProps
---@return boolean
local function overlaps(first, second)
  return first.top <= second.bottom
    and second.top <= first.bottom
    and first.left <= second.right
    and second.left <= first.right
end

---@param outer ScreenRectProps
---@param inner ScreenRectProps
---@return boolean
local function contains(outer, inner)
  return inner.top >= outer.top
    and inner.bottom <= outer.bottom
    and inner.left >= outer.left
    and inner.right <= outer.right
end

---@param win integer
---@return ScreenRectProps?
local function text_area_rect(win)
  local window_info = vim.fn.getwininfo(win)[1]
  if not window_info then return nil end
  local top = window_info.winrow + (window_info.winbar or 0)
  return {
    top = top,
    left = window_info.wincol + window_info.textoff,
    bottom = top + window_info.height - 1,
    right = window_info.wincol + window_info.width - 1,
  }
end

---@param win integer
---@return boolean
local function is_floating(win)
  return vim.api.nvim_win_get_config(win).relative ~= ''
end

---@param win integer
---@return ScreenRectProps?
local function floating_rect(win)
  local window_info = vim.fn.getwininfo(win)[1]
  if not window_info then return nil end
  local border = vim.api.nvim_win_get_config(win).border
  local has_border = border ~= nil
    and border ~= NO_BORDER
    and not (type(border) == 'table' and #border == 0)
  local border_width = has_border and BORDER_WIDTH or 0
  return {
    top = window_info.winrow - border_width,
    left = window_info.wincol - border_width,
    bottom = window_info.winrow + window_info.height - 1 + border_width,
    right = window_info.wincol + window_info.width - 1 + border_width,
  }
end

---@return ScreenRectProps[]
local function collect_covering_rects()
  ---@type ScreenRectProps[]
  local rects = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if is_floating(win) then rects[#rects + 1] = floating_rect(win) end
  end
  local popup = vim.fn.pum_getpos()
  if popup and popup.height then
    rects[#rects + 1] = {
      top = popup.row + 1,
      left = popup.col + 1,
      bottom = popup.row + popup.height,
      right = popup.col + popup.width + (popup.scrollbar and 1 or 0),
    }
  end
  return rects
end

---@return integer
local function last_drawable_row()
  return math.min(vim.o.lines - vim.o.cmdheight, vim.o.lines - LAST_ROW_MARGIN)
end

---@param image_rect ScreenRectProps
---@param window_rect ScreenRectProps
---@param covering_rects ScreenRectProps[]
---@return boolean
local function is_drawable(image_rect, window_rect, covering_rects)
  if not contains(window_rect, image_rect) then return false end
  if image_rect.bottom > last_drawable_row() then return false end
  for _, covering_rect in ipairs(covering_rects) do
    if overlaps(image_rect, covering_rect) then return false end
  end
  return true
end

---@param win integer
---@param placements ImagePlacementProps[]
---@param covering_rects ScreenRectProps[]
---@param screen_placements ScreenImagePlacementProps[]
local function collect_window(
  win,
  placements,
  covering_rects,
  screen_placements
)
  local window_rect = text_area_rect(win)
  if not window_rect then return end
  for _, placement in ipairs(placements) do
    local image = graphics_image_registry.positioned(placement.image_id)
    local position = image
      and vim.fn.screenpos(win, placement.row + 1, placement.col + 1)
    if image and position and position.row > 0 then
      ---@type ScreenRectProps
      local image_rect = {
        top = position.row,
        left = position.col,
        bottom = position.row + image.rows - 1,
        right = position.col + image.columns - 1,
      }
      if is_drawable(image_rect, window_rect, covering_rects) then
        screen_placements[#screen_placements + 1] = {
          screen_row = position.row,
          screen_col = position.col,
          image_id = placement.image_id,
        }
      end
    end
  end
end

---@return ScreenImagePlacementProps[]
function screen_image_geometry.collect()
  ---@type ScreenImagePlacementProps[]
  local screen_placements = {}
  local covering_rects = collect_covering_rects()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if not is_floating(win) and buffer_state_store.is_attached(buf) then
      collect_window(
        win,
        image_placement_registry.list(buf),
        covering_rects,
        screen_placements
      )
    end
  end
  return screen_placements
end

return screen_image_geometry
