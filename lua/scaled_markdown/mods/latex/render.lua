local latex_block_dto_builder =
  require 'scaled_markdown.mods.latex.latex_block_dto_builder'
local latex_converter = require 'scaled_markdown.mods.latex.latex_converter'
local latex_highlight = require 'scaled_markdown.mods.latex.highlight'
local latex_symbol_highlighter =
  require 'scaled_markdown.mods.latex.latex_symbol_highlighter'
local utf8_text = require 'scaled_markdown.core.text.utf8_text'

local HIDDEN_TEXT = ''
local INLINE_POSITION = 'inline'
local TRAILING_WHITESPACE_PATTERN = '%s+$'

---@alias LatexContextProps RenderContextProps<LatexConfigProps>

---@class latex_render
local latex_render = {}

---@param latex_block_dto LatexBlockProps
---@param writer ExtmarkWriterProps
---@return boolean
local function is_any_row_revealed(latex_block_dto, writer)
  for _, row_slice in ipairs(latex_block_dto.row_slices) do
    if writer.is_revealed(row_slice.row) then return true end
  end
  return false
end

---@param latex_block_dto LatexBlockProps
---@param writer ExtmarkWriterProps
local function conceal_source_rows(latex_block_dto, writer)
  for _, row_slice in ipairs(latex_block_dto.row_slices) do
    if row_slice.end_col > row_slice.start_col then
      writer.set_extmark(row_slice.row, row_slice.start_col, {
        end_col = row_slice.end_col,
        conceal = HIDDEN_TEXT,
      })
    end
  end
end

---@param padding_width integer
---@param text string
---@param mod_config LatexConfigProps
---@return [string, string][]
local function build_chunks(padding_width, text, mod_config)
  ---@type [string, string][]
  local chunks = {}
  if padding_width > 0 then
    chunks[1] = { string.rep(' ', padding_width), latex_highlight.GROUPS.MATH }
  end
  if not mod_config.highlight_symbols then
    chunks[#chunks + 1] = { text, latex_highlight.GROUPS.MATH }
    return chunks
  end
  return vim.list_extend(chunks, latex_symbol_highlighter.to_chunks(text))
end

---@param row integer
---@param col integer
---@param chunks [string, string][]
---@param writer ExtmarkWriterProps
local function write_inline_chunks(row, col, chunks, writer)
  writer.set_extmark(row, col, {
    virt_text = chunks,
    virt_text_pos = INLINE_POSITION,
  })
end

---@param latex_block_dto LatexBlockProps
---@param context_dto LatexContextProps
local function render_linear(latex_block_dto, context_dto)
  if is_any_row_revealed(latex_block_dto, context_dto.writer) then return end
  conceal_source_rows(latex_block_dto, context_dto.writer)
  write_inline_chunks(
    latex_block_dto.anchor_row,
    latex_block_dto.anchor_col,
    build_chunks(
      0,
      latex_converter.convert(
        latex_block_dto.source,
        context_dto.mod_config.command_symbols
      ),
      context_dto.mod_config
    ),
    context_dto.writer
  )
end

---@param latex_block_dto LatexBlockProps
---@return integer
local function find_anchor_slice_index(latex_block_dto)
  for slice_index, row_slice in ipairs(latex_block_dto.row_slices) do
    if row_slice.row == latex_block_dto.anchor_row then return slice_index end
  end
  return 1
end

---@param latex_block_dto LatexBlockProps
---@param box_width integer
---@param context_dto LatexContextProps
---@return integer
local function resolve_left_width(latex_block_dto, box_width, context_dto)
  local anchor_prefix = context_dto
    .line_at(latex_block_dto.anchor_row)
    :sub(1, latex_block_dto.anchor_col)
  local left_width = utf8_text.display_width(anchor_prefix)
  if
    not latex_block_dto.is_display
    or not context_dto.mod_config.center_display_math
  then
    return left_width
  end
  return math.max(
    left_width,
    math.floor((context_dto.text_area_width - box_width) / 2)
  )
end

---@param line_count integer
---@return [string, string][][]
local function build_blank_lines(line_count)
  ---@type [string, string][][]
  local blank_lines = {}
  for line_index = 1, line_count do
    blank_lines[line_index] = {}
  end
  return blank_lines
end

---@param row integer
---@param virtual_lines [string, string][][]
---@param is_above boolean
---@param writer ExtmarkWriterProps
local function write_virtual_lines(row, virtual_lines, is_above, writer)
  if #virtual_lines == 0 then return end
  writer.set_extmark(row, 0, {
    virt_lines = virtual_lines,
    virt_lines_above = is_above,
  })
end

---@param latex_block_dto LatexBlockProps
---@param context_dto LatexContextProps
local function render_display_box(latex_block_dto, context_dto)
  local writer = context_dto.writer
  local row_slices = latex_block_dto.row_slices
  local box = latex_converter.layout(
    latex_block_dto.source,
    context_dto.mod_config.command_symbols
  )
  local first_line_slice_index = find_anchor_slice_index(latex_block_dto)
    - (box.baseline - 1)
  local lines_above_count = math.max(0, 1 - first_line_slice_index)
  local lines_below_count =
    math.max(0, first_line_slice_index + #box.lines - 1 - #row_slices)
  local first_row = row_slices[1].row
  local last_row = row_slices[#row_slices].row
  if is_any_row_revealed(latex_block_dto, writer) then
    write_virtual_lines(
      first_row,
      build_blank_lines(lines_above_count),
      true,
      writer
    )
    write_virtual_lines(
      last_row,
      build_blank_lines(lines_below_count),
      false,
      writer
    )
    return
  end
  conceal_source_rows(latex_block_dto, writer)
  local left_width = resolve_left_width(latex_block_dto, box.width, context_dto)
  ---@type [string, string][][]
  local lines_above = {}
  ---@type [string, string][][]
  local lines_below = {}
  for line_index, line in ipairs(box.lines) do
    local trimmed_line = line:gsub(TRAILING_WHITESPACE_PATTERN, '')
    local slice_index = first_line_slice_index + line_index - 1
    local row_slice = row_slices[slice_index]
    if row_slice then
      local prefix_width = utf8_text.display_width(
        context_dto.line_at(row_slice.row):sub(1, row_slice.start_col)
      )
      write_inline_chunks(
        row_slice.row,
        row_slice.start_col,
        build_chunks(
          math.max(0, left_width - prefix_width),
          trimmed_line,
          context_dto.mod_config
        ),
        writer
      )
    else
      local overflow_lines = slice_index < 1 and lines_above or lines_below
      overflow_lines[#overflow_lines + 1] =
        build_chunks(left_width, trimmed_line, context_dto.mod_config)
    end
  end
  write_virtual_lines(first_row, lines_above, true, writer)
  write_virtual_lines(last_row, lines_below, false, writer)
end

---@param capture_dto CaptureProps
---@param mod_context_dto RenderContextProps<ModConfigProps>
function latex_render.render(capture_dto, mod_context_dto)
  ---@type LatexContextProps
  local context_dto = mod_context_dto
  local latex_block_dto =
    latex_block_dto_builder.build(capture_dto, context_dto.line_at)
  if not latex_block_dto then return end
  if latex_block_dto.is_standalone then
    render_display_box(latex_block_dto, context_dto)
  else
    render_linear(latex_block_dto, context_dto)
  end
end

return latex_render
