





local CORE_CONSTANTS = require('scaled_markdown.core.constants')
local font_resolver = require('scaled_markdown.core.text_art.font_resolver')
local graphics_image_registry =
require('scaled_markdown.core.text_art.graphics_image_registry')
local graphics_placeholder_builder =
require('scaled_markdown.core.text_art.graphics_placeholder_builder')
local kitty_graphics_protocol =
require('scaled_markdown.core.terminal.kitty_graphics_protocol')
local terminal_capability =
require('scaled_markdown.core.terminal.terminal_capability')
local terminal_cell_size =
require('scaled_markdown.core.terminal.terminal_cell_size')
local process_runner = require('scaled_markdown.core.text_art.process_runner')

local MAGICK_EXECUTABLE = 'magick'
local IMAGE_FILE_SUFFIX = '-tty-graphics-protocol.png'
local LINE_HEIGHT_TO_POINT_SIZE = 0.82
local GRADIENT_FORMAT = '0,0 %s %%[fx:w-1],0 %s'
local CELL_EXTENT_FORMAT = '%%[fx:ceil(w/%d)*%d]x%%[fx:ceil(h/%d)*%d]'
local CAPTION_SIZE_FORMAT = '%dx'
local DIMENSIONS_FORMAT = '%w %h'
local DIMENSIONS_PATTERN = '^(%d+) (%d+)'

local graphics_renderer = {}


local function escape_caption_text(text)
   return (text:gsub('\\', '\\\\'):gsub('%%', '%%%%'))
end

local function build_render_command(
   font_file,
   style_props,
   cell_size,
   width,
   image_path)

   local point_size = style_props.line_height_cells *
   cell_size.height *
   LINE_HEIGHT_TO_POINT_SIZE
   return {
      MAGICK_EXECUTABLE,
      '-background',
      'none',
      '-fill',
      'white',
      '-font',
      font_file,
      '-pointsize',
      tostring(point_size),
      '-size',
      CAPTION_SIZE_FORMAT:format(width * cell_size.width),
      'caption:@-',
      '-define',
      'trim:edges=east',
      '-trim',
      '+repage',
      '-channel',
      'RGB',
      '-sparse-color',
      'Barycentric',
      GRADIENT_FORMAT:format(style_props.start_color, style_props.end_color),
      '+channel',
      '-gravity',
      'NorthWest',
      '-extent',
      CELL_EXTENT_FORMAT:format(
      cell_size.width,
      cell_size.width,
      cell_size.height,
      cell_size.height),

      '-write',
      image_path,
      '-format',
      DIMENSIONS_FORMAT,
      'info:',
   }
end

local function place_image(
   image_path,
   image_width,
   image_height,
   cell_size)

   local columns = math.ceil(image_width / cell_size.width)
   local rows = math.ceil(image_height / cell_size.height)
   if rows > graphics_placeholder_builder.max_rows() then
      os.remove(image_path)
      return nil
   end
   local image_id, highlight_group = graphics_image_registry.allocate()
   kitty_graphics_protocol.transmit_temporary_file(
   image_id,
   image_path,
   columns,
   rows)

   return {
      lines = graphics_placeholder_builder.build_lines(columns, rows),
      highlight = highlight_group,
   }
end

function graphics_renderer.is_available()
   return vim.fn.executable(MAGICK_EXECUTABLE) == 1 and
   font_resolver.is_available() and
   terminal_capability.supports_kitty_graphics()
end

function graphics_renderer.render_async(
   text,
   style_props,
   width,
   on_done)

   local font_file = font_resolver.resolve(style_props.font)
   if not font_file then
      on_done(nil)
      return
   end
   local cell_size = terminal_cell_size.resolve()
   local image_path = vim.fn.tempname() .. IMAGE_FILE_SUFFIX
   local command =
   build_render_command(font_file, style_props, cell_size, width, image_path)
   local process_options = {
      stdin = escape_caption_text(text),
      text = true,
      timeout = CORE_CONSTANTS.TEXT_ART_TIMEOUT_MS,
   }
   process_runner.run_async(
   command,
   process_options,
   function(result)
      local image_width, image_height = (result.stdout or ''):match(
      DIMENSIONS_PATTERN)

      vim.schedule(function()
         if result.code ~= 0 or not image_width then
            on_done(nil)
            return
         end
         on_done(
         place_image(
         image_path,
         tonumber(image_width),
         tonumber(image_height),
         cell_size))


      end)
   end)

end

return graphics_renderer
