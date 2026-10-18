local type CaptureProps = require 'scaled_markdown.core.types.capture_props'
local type HeadingConfigProps =
  require 'scaled_markdown.mods.heading.config_props'
local type HeadingProps = require 'scaled_markdown.mods.heading.heading_props'
local type ModConfigProps =
  require 'scaled_markdown.core.types.mod_config_props'
local type RenderContextProps =
  require 'scaled_markdown.core.types.render_context_props'
local type TextArtProps = require 'scaled_markdown.core.types.text_art_props'
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

local type HeadingContextProps = RenderContextProps<HeadingConfigProps>

local record heading_render
end

local function measure_widest(lines: {string}): integer
  local widest = 0
  for _, line in ipairs(lines) do
    widest = math.max(widest, utf8_text.display_width(line))
  end
  return widest
end

local function hide_setext_underline(
  heading_dto: HeadingProps,
  context_dto: HeadingContextProps
)
  if heading_dto.underline_row then
    context_dto.writer.set_extmark(
      heading_dto.underline_row,
      0,
      { conceal_lines = '' }
    )
  end
end

local function color_art_line(
  art_line: string,
  art_width: integer,
  text_art_dto: TextArtProps
): {vim.VirtualChunkProps}
  if text_art_dto.highlight then
    return { { art_line, text_art_dto.highlight } }
  end
  return gradient_chunks.from_text(art_line, art_width)
end

local function build_art_line_chunks(
  art_line: string,
  art_width: integer,
  text_art_dto: TextArtProps,
  heading_dto: HeadingProps
): {vim.VirtualChunkProps}
  local chunks = color_art_line(art_line, art_width, text_art_dto)
  if heading_dto.start_col > 0 then
    table.insert(
      chunks,
      1,
      {
        string.rep(' ', heading_dto.start_col),
        CORE_CONSTANTS.PADDING_HIGHLIGHT,
      }
    )
  end
  return chunks
end

local function measure_source_width(
  heading_dto: HeadingProps,
  context_dto: HeadingContextProps
): integer
  return utf8_text.display_width(context_dto.line_at(heading_dto.row))
    - heading_dto.start_col
end

local function measure_chunks_width(chunks: {vim.VirtualChunkProps}): integer
  local width = 0
  for _, chunk in ipairs(chunks) do
    width = width + utf8_text.display_width(chunk[1])
  end
  return width
end

local function append_padding(
  chunks: {vim.VirtualChunkProps},
  covered_width: integer,
  target_width: integer
): {vim.VirtualChunkProps}
  if target_width > covered_width then
    chunks[#chunks + 1] = {
      string.rep(' ', target_width - covered_width),
      CORE_CONSTANTS.PADDING_HIGHLIGHT,
    }
  end
  return chunks
end

local function render_text_art(
  heading_dto: HeadingProps,
  text_art_dto: TextArtProps,
  context_dto: HeadingContextProps
)
  local art_lines = text_art_dto.lines
  local art_width = measure_widest(art_lines)
  local first_line_chunks = append_padding(
    color_art_line(art_lines[1], art_width, text_art_dto),
    utf8_text.display_width(art_lines[1]),
    measure_source_width(heading_dto, context_dto)
  )
  local extra_lines: {{vim.VirtualChunkProps}} = {}
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

local function render_single_line_text(
  heading_dto: HeadingProps,
  context_dto: HeadingContextProps
)
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

function heading_render.render(
  capture_dto: CaptureProps,
  mod_context_dto: RenderContextProps<ModConfigProps>
)
  local context_dto = mod_context_dto as HeadingContextProps
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
