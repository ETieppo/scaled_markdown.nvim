local type GlyphBoxProps = require 'scaled_markdown.core.types.glyph_box_props'
local CORE_CONSTANTS = require 'scaled_markdown.core.constants'
local process_runner = require 'scaled_markdown.core.text_art.process_runner'

local MAGICK_EXECUTABLE <const> = 'magick'
local GLYPH_BOX_REFERENCE_TEXT <const> = 'Hbdfgjklpqy'
local TRIM_INFO_PATTERN <const> = '%d+x(%d+) %d+x%d+[+-]%d+%+(%d+)'
local CANVAS_COLOR <const> = 'black'
local GLYPH_COLOR <const> = 'white'
local KEY_SEPARATOR <const> = '\31'
local UNMEASURED_BOX_MARKER <const> = false

local record typeface_glyph_box
end

local glyph_box_by_key: {string: GlyphBoxProps | boolean} = {}

local function build_measure_command(
  font_file: string,
  point_size: integer
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
    tostring(point_size),
    'label:' .. GLYPH_BOX_REFERENCE_TEXT,
    '-trim',
    'info:',
  }
end

local function measure(font_file: string, point_size: integer): GlyphBoxProps
  local result = process_runner.run_sync(
    build_measure_command(font_file, point_size),
    { text = true },
    CORE_CONSTANTS.TEXT_ART_TIMEOUT_MS
  )
  local height, top = (result.stdout or ''):match(TRIM_INFO_PATTERN)
  if result.code ~= 0 or not height then return nil end
  return {
    height = math.floor(tonumber(height)),
    top = math.floor(tonumber(top)),
  }
end

function typeface_glyph_box.resolve(
  font_file: string,
  point_size: integer
): GlyphBoxProps
  local key = font_file .. KEY_SEPARATOR .. point_size
  if glyph_box_by_key[key] == nil then
    glyph_box_by_key[key] = measure(font_file, point_size)
      or UNMEASURED_BOX_MARKER
  end
  local glyph_box = glyph_box_by_key[key]
  return glyph_box is GlyphBoxProps and glyph_box or nil
end

return typeface_glyph_box
