local type CaptureProps = require 'scaled_markdown.core.types.capture_props'
local type HeadingProps = require 'scaled_markdown.mods.heading.heading_props'
local HEADING_CAPTURE_ENUM =
  require 'scaled_markdown.mods.heading.heading_capture_enum'

local ATX_MARKER_LEVEL_PATTERN <const> = '^atx_h(%d)_marker$'
local SETEXT_UNDERLINE_LEVEL_PATTERN <const> = '^setext_h(%d)_underline$'

local record heading_dto_builder
end

local function find_child(
  node: vim.TSNodeProps,
  predicate: function(vim.TSNodeProps): boolean
): vim.TSNodeProps
  for child in node:iter_children() do
    if predicate(child) then return child end
  end
  return nil
end

local function build_atx(capture_dto: CaptureProps, buf: integer): HeadingProps
  local marker_node = find_child(
    capture_dto.node,
    function(child: vim.TSNodeProps): boolean
      return child:type():match(ATX_MARKER_LEVEL_PATTERN) ~= nil
    end
  )
  local content_node = capture_dto.node:field('heading_content')[1]
  if not marker_node or not content_node then return nil end
  return {
    level = math.floor(
      tonumber(marker_node:type():match(ATX_MARKER_LEVEL_PATTERN))
    ),
    text = vim.trim(vim.treesitter.get_node_text(content_node, buf)),
    row = capture_dto.start_row,
    start_col = capture_dto.start_col,
    underline_row = nil,
  }
end

local function build_setext(
  capture_dto: CaptureProps,
  buf: integer
): HeadingProps
  local underline_node = find_child(
    capture_dto.node,
    function(child: vim.TSNodeProps): boolean
      return child:type():match(SETEXT_UNDERLINE_LEVEL_PATTERN) ~= nil
    end
  )
  local content_node = capture_dto.node:field('heading_content')[1]
  if not underline_node or not content_node then return nil end
  local content_lines = vim.split(
    vim.treesitter.get_node_text(content_node, buf),
    '\n',
    { plain = true }
  )
  return {
    level = math.floor(tonumber(
      underline_node:type():match(SETEXT_UNDERLINE_LEVEL_PATTERN)
    )),
    text = vim.trim(content_lines[1] or ''),
    row = capture_dto.start_row,
    start_col = capture_dto.start_col,
    underline_row = (underline_node:range()),
  }
end

function heading_dto_builder.build(
  capture_dto: CaptureProps,
  buf: integer
): HeadingProps
  if capture_dto.name == HEADING_CAPTURE_ENUM.ATX_HEADING then
    return build_atx(capture_dto, buf)
  end
  return build_setext(capture_dto, buf)
end

return heading_dto_builder
