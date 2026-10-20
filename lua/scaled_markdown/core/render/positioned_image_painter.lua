local GRAPHICS_PROTOCOL_ENUM =
  require 'scaled_markdown.core.enums.graphics_protocol_enum'
local graphics_image_registry =
  require 'scaled_markdown.core.text_art.graphics_image_registry'
local screen_image_geometry =
  require 'scaled_markdown.core.render.screen_image_geometry'
local terminal_capability =
  require 'scaled_markdown.core.terminal.terminal_capability'

local SYNCHRONIZED_OUTPUT_START = '\27[?2026h'
local SYNCHRONIZED_OUTPUT_END = '\27[?2026l'
local SAVE_CURSOR = '\0277'
local RESTORE_CURSOR = '\0278'
local MOVE_CURSOR_FORMAT = '\27[%d;%dH'
local PLACEMENT_SIGNATURE_FORMAT = '%d@%d,%d'
local SIGNATURE_SEPARATOR = ';'
local EMPTY_SIGNATURE = ''
local CLEAR_AND_REDRAW_COMMAND = 'mode'

---@class positioned_image_painter
local positioned_image_painter = {}

local painted_signature = EMPTY_SIGNATURE
local is_paint_scheduled = false
local needs_repaint = false

---@param screen_placements ScreenImagePlacementProps[]
---@return string
local function build_signature(screen_placements)
  ---@type string[]
  local entries = {}
  for index, screen_placement in ipairs(screen_placements) do
    entries[index] = PLACEMENT_SIGNATURE_FORMAT:format(
      screen_placement.image_id,
      screen_placement.screen_row,
      screen_placement.screen_col
    )
  end
  return table.concat(entries, SIGNATURE_SEPARATOR)
end

---@param screen_placements ScreenImagePlacementProps[]
---@return string
function positioned_image_painter.build_output(screen_placements)
  ---@type string[]
  local parts = { SYNCHRONIZED_OUTPUT_START, SAVE_CURSOR }
  for _, screen_placement in ipairs(screen_placements) do
    local image = graphics_image_registry.positioned(screen_placement.image_id)
    if image then
      parts[#parts + 1] = MOVE_CURSOR_FORMAT:format(
        screen_placement.screen_row,
        screen_placement.screen_col
      )
      parts[#parts + 1] = image.payload
    end
  end
  parts[#parts + 1] = RESTORE_CURSOR
  parts[#parts + 1] = SYNCHRONIZED_OUTPUT_END
  return table.concat(parts)
end

function positioned_image_painter.paint()
  if terminal_capability.protocol() ~= GRAPHICS_PROTOCOL_ENUM.SIXEL then
    painted_signature = EMPTY_SIGNATURE
    needs_repaint = false
    return
  end
  local screen_placements = screen_image_geometry.collect()
  local signature = build_signature(screen_placements)
  if signature == painted_signature and not needs_repaint then return end
  if
    painted_signature ~= EMPTY_SIGNATURE and signature ~= painted_signature
  then
    vim.cmd(CLEAR_AND_REDRAW_COMMAND)
  else
    vim.api.nvim__redraw { flush = true }
  end
  painted_signature = signature
  needs_repaint = false
  if #screen_placements == 0 then return end
  vim.api.nvim_ui_send(positioned_image_painter.build_output(screen_placements))
end

function positioned_image_painter.schedule()
  if is_paint_scheduled then return end
  is_paint_scheduled = true
  vim.schedule(function()
    is_paint_scheduled = false
    positioned_image_painter.paint()
  end)
end

function positioned_image_painter.request_repaint()
  needs_repaint = true
  positioned_image_painter.schedule()
end

function positioned_image_painter.reset()
  painted_signature = EMPTY_SIGNATURE
  needs_repaint = false
end

return positioned_image_painter
