local CORE_CONSTANTS = require 'scaled_markdown.core.constants'
local gradient_chunks = require 'scaled_markdown.core.highlight.gradient_chunks'
local heading_dto_builder =
  require 'scaled_markdown.mods.heading.heading_dto_builder'
local heading_line_builder =
  require 'scaled_markdown.mods.heading.heading_line_builder'
local heading_style_resolver =
  require 'scaled_markdown.mods.heading.heading_style_resolver'
local text_art_service =
  require 'scaled_markdown.core.text_art.text_art_service'
local utf8_text = require 'scaled_markdown.core.text.utf8_text'

---@alias HeadingContextProps RenderContextProps<HeadingConfigProps>

---@class heading_render
local heading_render = {}

---@param lines string[]
---@return integer
local function measure_widest(lines)
  local widest = 0
  for _, line in ipairs(lines) do
    widest = math.max(widest, utf8_text.display_width(line))
  end
  return widest
end

---@param heading_dto HeadingProps
---@param context_dto HeadingContextProps
local function hide_setext_underline(heading_dto, context_dto)
  if heading_dto.underline_row then
    context_dto.writer.set_extmark(
      heading_dto.underline_row,
      0,
      { conceal_lines = '' }
    )
  end
end

---@param art_line string
---@param art_width integer
---@param text_art_dto TextArtProps
---@return [string, string][]
local function color_art_line(art_line, art_width, text_art_dto)
  if text_art_dto.highlight then
    return { { art_line, text_art_dto.highlight } }
  end
  return gradient_chunks.from_text(art_line, art_width)
end

---@param art_line string
---@param art_width integer
---@param text_art_dto TextArtProps
---@param heading_dto HeadingProps
---@return [string, string][]
local function build_art_line_chunks(
  art_line,
  art_width,
  text_art_dto,
  heading_dto
)
  local chunks = color_art_line(art_line, art_width, text_art_dto)
  if heading_dto.start_col > 0 then
    table.insert(chunks, 1, {
      string.rep(' ', heading_dto.start_col),
      CORE_CONSTANTS.PADDING_HIGHLIGHT,
    })
  end
  return chunks
end

---@param heading_dto HeadingProps
---@param context_dto HeadingContextProps
---@return integer
local function measure_source_width(heading_dto, context_dto)
  return utf8_text.display_width(context_dto.line_at(heading_dto.row))
    - heading_dto.start_col
end

---@param chunks [string, string][]
---@return integer
local function measure_chunks_width(chunks)
  local width = 0
  for _, chunk in ipairs(chunks) do
    width = width + utf8_text.display_width(chunk[1])
  end
  return width
end

---@param chunks [string, string][]
---@param covered_width integer
---@param target_width integer
---@return [string, string][]
local function append_padding(chunks, covered_width, target_width)
  if target_width > covered_width then
    chunks[#chunks + 1] = {
      string.rep(' ', target_width - covered_width),
      CORE_CONSTANTS.PADDING_HIGHLIGHT,
    }
  end
  return chunks
end

---@param heading_dto HeadingProps
---@param text_art_dto TextArtProps
---@param context_dto HeadingContextProps
local function render_text_art(heading_dto, text_art_dto, context_dto)
  local art_lines = text_art_dto.lines
  local art_width = measure_widest(art_lines)
  local first_line_chunks = append_padding(
    color_art_line(art_lines[1], art_width, text_art_dto),
    utf8_text.display_width(art_lines[1]),
    measure_source_width(heading_dto, context_dto)
  )
  ---@type [string, string][][]
  local extra_lines = {}
  for line_index = 2, #art_lines do
    extra_lines[#extra_lines + 1] = build_art_line_chunks(
      art_lines[line_index],
      art_width,
      text_art_dto,
      heading_dto
    )
  end
  context_dto.writer.set_extmark(heading_dto.row, heading_dto.start_col, {
    virt_text = first_line_chunks,
    virt_text_pos = 'overlay',
    virt_lines = extra_lines,
  })
  hide_setext_underline(heading_dto, context_dto)
end

---@param heading_dto HeadingProps
---@param context_dto HeadingContextProps
local function render_single_line_text(heading_dto, context_dto)
  local line_chunks =
    heading_line_builder.build(heading_dto, context_dto.mod_config)
  local text_chunks = append_padding(
    line_chunks,
    measure_chunks_width(line_chunks),
    measure_source_width(heading_dto, context_dto)
  )
  context_dto.writer.set_extmark(heading_dto.row, heading_dto.start_col, {
    virt_text = text_chunks,
    virt_text_pos = 'overlay',
  })
  hide_setext_underline(heading_dto, context_dto)
end

---@param capture_dto CaptureProps
---@param mod_context_dto RenderContextProps<ModConfigProps>
function heading_render.render(capture_dto, mod_context_dto)
  ---@type HeadingContextProps
  local context_dto = mod_context_dto
  local heading_dto = heading_dto_builder.build(capture_dto, context_dto.buf)
  if not heading_dto or heading_dto.text == '' then return end
  local available_width =
    math.max(1, context_dto.text_area_width - heading_dto.start_col)
  local style_by_renderer = heading_style_resolver.resolve(
    context_dto.mod_config.styles,
    heading_dto.level
  )
  local text_art_dto = text_art_service.request(
    heading_dto.text,
    style_by_renderer,
    available_width
  )
  if text_art_dto then
    render_text_art(heading_dto, text_art_dto, context_dto)
  else
    render_single_line_text(heading_dto, context_dto)
  end
end

return heading_render
