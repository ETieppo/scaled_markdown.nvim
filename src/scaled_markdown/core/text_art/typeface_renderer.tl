local type GlyphBoxProps = require 'scaled_markdown.core.types.glyph_box_props'
local type TextArtProps = require 'scaled_markdown.core.types.text_art_props'
local type TextArtRendererProps =
  require 'scaled_markdown.core.types.text_art_renderer_props'
local type TextArtStyleProps =
  require 'scaled_markdown.core.types.text_art_style_props'
local CORE_CONSTANTS = require 'scaled_markdown.core.constants'
local art_lines_parser =
  require 'scaled_markdown.core.text_art.art_lines_parser'
local font_resolver = require 'scaled_markdown.core.text_art.font_resolver'
local typeface_glyph_box =
  require 'scaled_markdown.core.text_art.typeface_glyph_box'
local process_runner = require 'scaled_markdown.core.text_art.process_runner'

local MAGICK_EXECUTABLE <const> = 'magick'
local CHAFA_EXECUTABLE <const> = 'chafa'
local RENDER_POINT_SIZE <const> = 160
local HORIZONTAL_MARGIN <const> = '4x0'
local CANVAS_COLOR <const> = 'black'
local GLYPH_COLOR <const> = 'white'
local CHAFA_WORK_FACTOR <const> = 9
local GLYPH_BOX_CROP_FORMAT <const> = '%dx%d+0+%d'
local UNBOUNDED_CROP_WIDTH <const> = 100000

local record typeface_renderer is TextArtRendererProps
end

local function escape_label_text(text: string): string
  return (text:gsub('\\', '\\\\'):gsub('%%', '%%%%'))
end

local function build_rasterize_command(
  font_file: string,
  glyph_box: GlyphBoxProps
): {string}
  return {
    MAGICK_EXECUTABLE,
    '-background',
    CANVAS_COLOR,
    '-fill',
    GLYPH_COLOR,
    '-font',
    font_file,
    '-pointsize',
    tostring(RENDER_POINT_SIZE),
    'label:@-',
    '-crop',
    GLYPH_BOX_CROP_FORMAT:format(
      UNBOUNDED_CROP_WIDTH,
      glyph_box.height,
      glyph_box.top
    ),
    '+repage',
    '-define',
    'trim:edges=east,west',
    '-trim',
    '+repage',
    '-bordercolor',
    CANVAS_COLOR,
    '-border',
    HORIZONTAL_MARGIN,
    'png:-',
  }
end

local function build_symbolize_command(
  style_props: TextArtStyleProps,
  width: integer
): {string}
  return {
    CHAFA_EXECUTABLE,
    '--format',
    'symbols',
    '--symbols',
    style_props.symbols,
    '--colors',
    'none',
    '--polite',
    'on',
    '--dither',
    'none',
    '--work',
    tostring(CHAFA_WORK_FACTOR),
    '--size',
    ('%dx%d'):format(width, style_props.rows),
    '-',
  }
end

function typeface_renderer.is_available(): boolean
  return vim.fn.executable(MAGICK_EXECUTABLE) == 1
    and vim.fn.executable(CHAFA_EXECUTABLE) == 1
    and font_resolver.is_available()
end

function typeface_renderer.render_async(
  text: string,
  style_props: TextArtStyleProps,
  width: integer,
  on_done: function(TextArtProps)
)
  local font_file = font_resolver.resolve(style_props.font)
  local glyph_box = font_file
    and typeface_glyph_box.resolve(font_file, RENDER_POINT_SIZE)
  if not glyph_box then
    on_done(nil)
    return
  end
  local process_options: vim.SystemOptionsProps = {
    stdin = escape_label_text(text),
    timeout = CORE_CONSTANTS.TEXT_ART_TIMEOUT_MS,
  }
  process_runner.run_async(
    build_rasterize_command(font_file, glyph_box),
    process_options,
    function(rasterize_result: vim.SystemCompletedProps)
      if rasterize_result.code ~= 0 or not rasterize_result.stdout then
        on_done(nil)
        return
      end
      process_runner.run_async(build_symbolize_command(style_props, width), {
        stdin = rasterize_result.stdout,
        text = true,
        timeout = CORE_CONSTANTS.TEXT_ART_TIMEOUT_MS,
      }, function(symbolize_result: vim.SystemCompletedProps)
        local is_success = symbolize_result.code == 0
        on_done(
          is_success
              and art_lines_parser.to_result(
                art_lines_parser.split_lines(symbolize_result.stdout)
              )
            or nil
        )
      end)
    end
  )
end

return typeface_renderer
