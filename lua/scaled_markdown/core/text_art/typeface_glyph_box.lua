
local CORE_CONSTANTS = require('scaled_markdown.core.constants')
local process_runner = require('scaled_markdown.core.text_art.process_runner')

local MAGICK_EXECUTABLE = 'magick'
local GLYPH_BOX_REFERENCE_TEXT = 'Hbdfgjklpqy'
local TRIM_INFO_PATTERN = '%d+x(%d+) %d+x%d+[+-]%d+%+(%d+)'
local CANVAS_COLOR = 'black'
local GLYPH_COLOR = 'white'
local KEY_SEPARATOR = '\31'
local UNMEASURED_BOX_MARKER = false

local typeface_glyph_box = {}


local glyph_box_by_key = {}

local function build_measure_command(
   font_file,
   point_size)

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

local function measure(font_file, point_size)
   local result = process_runner.run_sync(
   build_measure_command(font_file, point_size),
   { text = true },
   CORE_CONSTANTS.TEXT_ART_TIMEOUT_MS)

   local height, top = (result.stdout or ''):match(TRIM_INFO_PATTERN)
   if result.code ~= 0 or not height then return nil end
   return {
      height = math.floor(tonumber(height)),
      top = math.floor(tonumber(top)),
   }
end

function typeface_glyph_box.resolve(
   font_file,
   point_size)

   local key = font_file .. KEY_SEPARATOR .. point_size
   if glyph_box_by_key[key] == nil then
      glyph_box_by_key[key] = measure(font_file, point_size) or
      UNMEASURED_BOX_MARKER
   end
   local glyph_box = glyph_box_by_key[key]
   return type(glyph_box) == "table" and glyph_box or nil
end

return typeface_glyph_box
