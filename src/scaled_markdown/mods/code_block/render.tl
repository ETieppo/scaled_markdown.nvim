local type CaptureProps = require 'scaled_markdown.core.types.capture_props'
local type CodeBlockConfigProps =
  require 'scaled_markdown.mods.code_block.config_props'
local type CodeBlockProps =
  require 'scaled_markdown.mods.code_block.code_block_props'
local type ModConfigProps =
  require 'scaled_markdown.core.types.mod_config_props'
local type RenderContextProps =
  require 'scaled_markdown.core.types.render_context_props'
local CORE_CONSTANTS = require 'scaled_markdown.core.constants'
local border_line_builder =
  require 'scaled_markdown.core.border.border_line_builder'
local code_block_dto_builder =
  require 'scaled_markdown.mods.code_block.code_block_dto_builder'
local gradient_chunks = require 'scaled_markdown.core.highlight.gradient_chunks'
local gradient_palette =
  require 'scaled_markdown.core.highlight.gradient_palette'
local utf8_text = require 'scaled_markdown.core.text.utf8_text'

local BORDER_COLUMN_COUNT <const> = 2
local TITLE_DECORATION_WIDTH <const> = 6

local type CodeBlockContextProps = RenderContextProps<CodeBlockConfigProps>

local record code_block_render
end

local function measure_content_width(
  code_block_dto: CodeBlockProps,
  context_dto: CodeBlockContextProps
): integer
  local widest = 0
  for row = code_block_dto.first_content_row, code_block_dto.last_content_row do
    local line_width = utf8_text.display_width(context_dto.line_at(row))
    widest = math.max(widest, line_width - code_block_dto.left_col)
  end
  return widest
end

local function resolve_box_width(
  code_block_dto: CodeBlockProps,
  context_dto: CodeBlockContextProps
): integer
  local mod_config = context_dto.mod_config
  local content_width = measure_content_width(code_block_dto, context_dto)
  local padded_width = content_width
    + BORDER_COLUMN_COUNT
    + mod_config.horizontal_padding * 2
  local title_width = utf8_text.display_width(code_block_dto.language or '')
    + TITLE_DECORATION_WIDTH
  local available_width = context_dto.text_area_width - code_block_dto.left_col

  return math.min(
    math.max(padded_width, mod_config.min_width, title_width),
    available_width
  )
end

local function overlay_border(
  row: integer,
  border_text: string,
  code_block_dto: CodeBlockProps,
  context_dto: CodeBlockContextProps
)
  local source_width = utf8_text.display_width(context_dto.line_at(row))
    - code_block_dto.left_col
  local border_width = utf8_text.display_width(border_text)

  context_dto.writer.set_extmark(row, code_block_dto.left_col, {
    virt_text = gradient_chunks.from_segments({
      { text = border_text },
      {
        text = string.rep(' ', math.max(0, source_width - border_width)),
        highlight = CORE_CONSTANTS.PADDING_HIGHLIGHT,
      },
    }, border_width),
    virt_text_pos = 'overlay',
  })
end

local function render_side_borders(
  row: integer,
  highlight_group: string,
  box_width: integer,
  code_block_dto: CodeBlockProps,
  context_dto: CodeBlockContextProps
)
  local line = context_dto.line_at(row)
  local padding = string.rep(' ', context_dto.mod_config.horizontal_padding)
  local vertical = border_line_builder.vertical()

  context_dto.writer.set_extmark(
    row,
    math.min(code_block_dto.left_col, #line),
    {
      virt_text = {
        { vertical, highlight_group },
        { padding, CORE_CONSTANTS.PADDING_HIGHLIGHT },
      },
      virt_text_pos = 'inline',
    }
  )

  context_dto.writer.set_extmark(row, 0, {
    virt_text = { { vertical, highlight_group } },
    virt_text_win_col = code_block_dto.left_col + box_width - 1,
  })
end

local function attach_virtual_border(
  row: integer,
  border_text: string,
  is_above: boolean,
  code_block_dto: CodeBlockProps,
  context_dto: CodeBlockContextProps
)
  local chunks = gradient_chunks.from_text(border_text)
  table.insert(
    chunks,
    1,
    {
      string.rep(' ', code_block_dto.left_col),
      CORE_CONSTANTS.PADDING_HIGHLIGHT,
    }
  )

  context_dto.writer.set_extmark(row, 0, {
    virt_lines = { chunks },
    virt_lines_above = is_above,
  })
end

local function render_top_border(
  box_width: integer,
  code_block_dto: CodeBlockProps,
  context_dto: CodeBlockContextProps
)
  local border_text =
    border_line_builder.build_top(box_width, code_block_dto.language)
  if code_block_dto.opening_fence_row then
    overlay_border(
      code_block_dto.opening_fence_row,
      border_text,
      code_block_dto,
      context_dto
    )
  else
    attach_virtual_border(
      code_block_dto.first_content_row,
      border_text,
      true,
      code_block_dto,
      context_dto
    )
  end
end

local function render_bottom_border(
  box_width: integer,
  code_block_dto: CodeBlockProps,
  context_dto: CodeBlockContextProps
)
  local border_text = border_line_builder.build_bottom(box_width)
  if code_block_dto.closing_fence_row then
    overlay_border(
      code_block_dto.closing_fence_row,
      border_text,
      code_block_dto,
      context_dto
    )
  else
    attach_virtual_border(
      code_block_dto.last_content_row,
      border_text,
      false,
      code_block_dto,
      context_dto
    )
  end
end

function code_block_render.render(
  capture_dto: CaptureProps,
  mod_context_dto: RenderContextProps<ModConfigProps>
)
  local context_dto = mod_context_dto as CodeBlockContextProps
  local code_block_dto =
    code_block_dto_builder.build(capture_dto, context_dto.buf)
  local box_width = resolve_box_width(code_block_dto, context_dto)
  local first_row = code_block_dto.opening_fence_row
    or code_block_dto.first_content_row
  local last_row = code_block_dto.closing_fence_row
    or code_block_dto.last_content_row

  render_top_border(box_width, code_block_dto, context_dto)

  for row = code_block_dto.first_content_row, code_block_dto.last_content_row do
    local highlight_group = gradient_palette.group_for_position(
      row - first_row,
      last_row - first_row + 1
    )
    render_side_borders(
      row,
      highlight_group,
      box_width,
      code_block_dto,
      context_dto
    )
  end

  render_bottom_border(box_width, code_block_dto, context_dto)
end

return code_block_render
