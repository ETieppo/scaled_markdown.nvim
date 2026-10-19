local LINK_CAPTURE_ENUM = require 'scaled_markdown.mods.link.link_capture_enum'
local link_highlight = require 'scaled_markdown.mods.link.highlight'

local AUTOLINK_DELIMITER_WIDTH = 1
local LINK_TEXT_NODE_TYPE = 'link_text'

---@alias LinkContextProps RenderContextProps<LinkConfigProps>

---@class link_render
local link_render = {}

---@param link_node TSNode
---@return TSNode?
local function find_link_text_node(link_node)
  for child in link_node:iter_children() do
    if child:type() == LINK_TEXT_NODE_TYPE then return child end
  end
  return nil
end

---@param writer ExtmarkWriterProps
---@param row integer
---@param start_col integer
---@param end_row integer
---@param end_col integer
local function conceal_range(writer, row, start_col, end_row, end_col)
  writer.set_extmark(
    row,
    start_col,
    { end_row = end_row, end_col = end_col, conceal = '' }
  )
end

---@param writer ExtmarkWriterProps
---@param row integer
---@param col integer
---@param icon string
local function add_icon(writer, row, col, icon)
  writer.set_extmark(row, col, {
    virt_text = { { icon, link_highlight.GROUPS.ICON } },
    virt_text_pos = 'inline',
  })
end

---@param link_capture_dto CaptureProps
---@param context_dto LinkContextProps
local function render_labeled_link(link_capture_dto, context_dto)
  local text_node = find_link_text_node(link_capture_dto.node)
  if not text_node then return end
  local text_start_row, text_start_col, text_end_row, text_end_col =
    text_node:range()
  local writer = context_dto.writer
  add_icon(
    writer,
    link_capture_dto.start_row,
    link_capture_dto.start_col,
    context_dto.mod_config.icon
  )
  conceal_range(
    writer,
    link_capture_dto.start_row,
    link_capture_dto.start_col,
    text_start_row,
    text_start_col
  )
  writer.set_extmark(text_start_row, text_start_col, {
    end_row = text_end_row,
    end_col = text_end_col,
    hl_group = link_highlight.GROUPS.TEXT,
  })
  conceal_range(
    writer,
    text_end_row,
    text_end_col,
    link_capture_dto.end_row,
    link_capture_dto.end_col
  )
end

---@param capture_dto CaptureProps
---@param context_dto LinkContextProps
local function render_autolink(capture_dto, context_dto)
  local writer = context_dto.writer
  local row, start_col, end_col =
    capture_dto.start_row, capture_dto.start_col, capture_dto.end_col
  add_icon(writer, row, start_col, context_dto.mod_config.autolink_icon)
  conceal_range(
    writer,
    row,
    start_col,
    row,
    start_col + AUTOLINK_DELIMITER_WIDTH
  )
  writer.set_extmark(row, start_col + AUTOLINK_DELIMITER_WIDTH, {
    end_col = end_col - AUTOLINK_DELIMITER_WIDTH,
    hl_group = link_highlight.GROUPS.TEXT,
  })
  conceal_range(writer, row, end_col - AUTOLINK_DELIMITER_WIDTH, row, end_col)
end

---@param capture_dto CaptureProps
---@param mod_context_dto RenderContextProps<ModConfigProps>
function link_render.render(capture_dto, mod_context_dto)
  ---@type LinkContextProps
  local context_dto = mod_context_dto
  if capture_dto.name == LINK_CAPTURE_ENUM.AUTOLINK then
    render_autolink(capture_dto, context_dto)
  else
    render_labeled_link(capture_dto, context_dto)
  end
end

return link_render
