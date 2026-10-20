local CORE_CONSTANTS = require 'scaled_markdown.core.constants'
local border_line_builder =
  require 'scaled_markdown.core.border.border_line_builder'
local code_block_dto_builder =
  require 'scaled_markdown.mods.code_block.code_block_dto_builder'
local gradient_chunks = require 'scaled_markdown.core.highlight.gradient_chunks'
local gradient_palette =
  require 'scaled_markdown.core.highlight.gradient_palette'
local utf8_text = require 'scaled_markdown.core.text.utf8_text'

local BORDER_COLUMN_COUNT = 2
local TITLE_DECORATION_WIDTH = 6

---@alias CodeBlockContextProps RenderContextProps<CodeBlockConfigProps>

---@class code_block_render
local code_block_render = {}

---@param code_block_dto CodeBlockProps
---@param context_dto CodeBlockContextProps
---@return integer
local function measure_content_width(code_block_dto, context_dto)
  local widest = 0
  for row = code_block_dto.first_content_row, code_block_dto.last_content_row do
    local line_width = utf8_text.display_width(context_dto.line_at(row))
    widest = math.max(widest, line_width - code_block_dto.left_col)
  end
  return widest
end

---@param language string?
---@param mod_config CodeBlockConfigProps
---@return string?
local function build_title(language, mod_config)
  if not language or language == '' then return nil end
  local icon = mod_config.language_icons[language:lower()]
    or mod_config.default_language_icon
  return icon .. language
end

---@param code_block_dto CodeBlockProps
---@param context_dto CodeBlockContextProps
---@return integer
local function resolve_box_width(code_block_dto, context_dto)
  local mod_config = context_dto.mod_config
  local content_width = measure_content_width(code_block_dto, context_dto)
  local padded_width = content_width
    + BORDER_COLUMN_COUNT
    + mod_config.horizontal_padding * 2
  local title_width = utf8_text.display_width(
    build_title(code_block_dto.language, mod_config) or ''
  ) + TITLE_DECORATION_WIDTH
  local available_width = context_dto.text_area_width - code_block_dto.left_col

  return math.min(
    math.max(padded_width, mod_config.min_width, title_width),
    available_width
  )
end

---@param row integer
---@param border_text string
---@param code_block_dto CodeBlockProps
---@param context_dto CodeBlockContextProps
local function overlay_border(row, border_text, code_block_dto, context_dto)
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

---@param row integer
---@param highlight_group string
---@param box_width integer
---@param code_block_dto CodeBlockProps
---@param context_dto CodeBlockContextProps
local function render_side_borders(
  row,
  highlight_group,
  box_width,
  code_block_dto,
  context_dto
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

---@param row integer
---@param prefix_row integer
---@param border_text string
---@param is_above boolean
---@param code_block_dto CodeBlockProps
---@param context_dto CodeBlockContextProps
local function attach_virtual_border(
  row,
  prefix_row,
  border_text,
  is_above,
  code_block_dto,
  context_dto
)
  local chunks = vim.list_extend(
    context_dto.decorate_line_prefix(prefix_row, code_block_dto.left_col),
    gradient_chunks.from_text(border_text)
  )

  context_dto.writer.set_extmark(row, 0, {
    virt_lines = { chunks },
    virt_lines_above = is_above,
  })
end

---@param code_block_dto CodeBlockProps
---@return boolean
local function has_content_rows(code_block_dto)
  return code_block_dto.first_content_row <= code_block_dto.last_content_row
end

---@param fence_row integer?
---@param border_text string
---@param anchor_row integer
---@param is_above boolean
---@param code_block_dto CodeBlockProps
---@param context_dto CodeBlockContextProps
local function render_border(
  fence_row,
  border_text,
  anchor_row,
  is_above,
  code_block_dto,
  context_dto
)
  if fence_row and not has_content_rows(code_block_dto) then
    overlay_border(fence_row, border_text, code_block_dto, context_dto)
    return
  end
  if fence_row then
    if context_dto.writer.is_revealed(fence_row) then return end
    context_dto.writer.set_extmark(fence_row, 0, { conceal_lines = '' })
  end
  attach_virtual_border(
    anchor_row,
    fence_row or anchor_row,
    border_text,
    is_above,
    code_block_dto,
    context_dto
  )
end

---@param box_width integer
---@param code_block_dto CodeBlockProps
---@param context_dto CodeBlockContextProps
local function render_top_border(box_width, code_block_dto, context_dto)
  render_border(
    code_block_dto.opening_fence_row,
    border_line_builder.build_top(
      box_width,
      build_title(code_block_dto.language, context_dto.mod_config)
    ),
    code_block_dto.first_content_row,
    true,
    code_block_dto,
    context_dto
  )
end

---@param box_width integer
---@param code_block_dto CodeBlockProps
---@param context_dto CodeBlockContextProps
local function render_bottom_border(box_width, code_block_dto, context_dto)
  render_border(
    code_block_dto.closing_fence_row,
    border_line_builder.build_bottom(box_width),
    code_block_dto.last_content_row,
    false,
    code_block_dto,
    context_dto
  )
end

---@param capture_dto CaptureProps
---@param mod_context_dto RenderContextProps<ModConfigProps>
function code_block_render.render(capture_dto, mod_context_dto)
  ---@type CodeBlockContextProps
  local context_dto = mod_context_dto
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
