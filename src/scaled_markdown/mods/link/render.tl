local type CaptureProps = require 'scaled_markdown.core.types.capture_props'
local type ModConfigProps =
  require 'scaled_markdown.core.types.mod_config_props'
local type RenderContextProps =
  require 'scaled_markdown.core.types.render_context_props'
local type ExtmarkWriterProps =
  require 'scaled_markdown.core.types.extmark_writer_props'
local type LinkConfigProps = require 'scaled_markdown.mods.link.config_props'
local LINK_CAPTURE_ENUM = require 'scaled_markdown.mods.link.link_capture_enum'
local link_highlight = require 'scaled_markdown.mods.link.highlight'

local AUTOLINK_DELIMITER_WIDTH <const> = 1
local LINK_TEXT_NODE_TYPE <const> = 'link_text'

local type LinkContextProps = RenderContextProps<LinkConfigProps>

local record link_render
end

local function find_link_text_node(link_node: vim.TSNodeProps): vim.TSNodeProps
  for child in link_node:iter_children() do
    if child:type() == LINK_TEXT_NODE_TYPE then return child end
  end
  return nil
end

local function conceal_range(
  writer: ExtmarkWriterProps,
  row: integer,
  start_col: integer,
  end_row: integer,
  end_col: integer
)
  writer.set_extmark(
    row,
    start_col,
    { end_row = end_row, end_col = end_col, conceal = '' }
  )
end

local function add_icon(
  writer: ExtmarkWriterProps,
  row: integer,
  col: integer,
  icon: string
)
  writer.set_extmark(row, col, {
    virt_text = { { icon, link_highlight.GROUPS.ICON } },
    virt_text_pos = 'inline',
  })
end

local function render_labeled_link(
  link_capture_dto: CaptureProps,
  context_dto: LinkContextProps
)
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

local function render_autolink(
  capture_dto: CaptureProps,
  context_dto: LinkContextProps
)
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

function link_render.render(
  capture_dto: CaptureProps,
  mod_context_dto: RenderContextProps<ModConfigProps>
)
  local context_dto = mod_context_dto as LinkContextProps
  if capture_dto.name == LINK_CAPTURE_ENUM.AUTOLINK then
    render_autolink(capture_dto, context_dto)
  else
    render_labeled_link(capture_dto, context_dto)
  end
end

return link_render
