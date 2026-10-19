local coverage_rasterizer =
  require 'scaled_markdown.core.raster.coverage_rasterizer'
local font_face_loader = require 'scaled_markdown.core.font.font_face_loader'
local font_resolver = require 'scaled_markdown.core.text_art.font_resolver'
local glyph_run_rasterizer =
  require 'scaled_markdown.core.raster.glyph_run_rasterizer'
local graphics_image_registry =
  require 'scaled_markdown.core.text_art.graphics_image_registry'
local graphics_pixel_encoder =
  require 'scaled_markdown.core.text_art.graphics_pixel_encoder'
local graphics_placeholder_builder =
  require 'scaled_markdown.core.text_art.graphics_placeholder_builder'
local kitty_graphics_protocol =
  require 'scaled_markdown.core.terminal.kitty_graphics_protocol'
local terminal_capability =
  require 'scaled_markdown.core.terminal.terminal_capability'
local terminal_cell_size =
  require 'scaled_markdown.core.terminal.terminal_cell_size'
local text_line_layout = require 'scaled_markdown.core.layout.text_line_layout'
local text_word_wrapper =
  require 'scaled_markdown.core.layout.text_word_wrapper'

local IMAGE_FILE_SUFFIX = '-tty-graphics-protocol.rgba'
local WRITE_BINARY_MODE = 'wb'
local LINE_HEIGHT_TO_POINT_SIZE = 0.82
local LINE_SPACING_PIXELS = 1
local CANVAS_PADDING_PIXELS = 2
local NO_INK_WIDTH = 0
local MIN_VISIBLE_COVERAGE = 0.5 / 255

---@class GraphicsImageProps
---@field path string
---@field width integer
---@field height integer

---@class graphics_renderer: TextArtRendererProps
local graphics_renderer = {}

---@param bitmap CoverageBitmapProps
---@return integer
local function measure_ink_width(bitmap)
  for column = bitmap.width, 1, -1 do
    for row = 0, bitmap.height - 1 do
      if bitmap.values[row * bitmap.width + column] >= MIN_VISIBLE_COVERAGE then
        return column
      end
    end
  end
  return NO_INK_WIDTH
end

---@param value number
---@param step integer
---@return integer
local function round_up_to_multiple(value, step)
  return math.ceil(value / step) * step
end

---@param face FontFaceProps
---@param lines string[]
---@param scale number
---@return CoverageBitmapProps
local function rasterize_lines(face, lines, scale)
  local ascent = math.ceil(face.ascender * scale)
  local line_height = ascent
    - math.floor(face.descender * scale)
    + LINE_SPACING_PIXELS
  local layouts = vim.tbl_map(
    ---@param line string
    ---@return TextLineLayoutProps
    function(line) return text_line_layout.layout(face, line) end,
    lines
  )
  ---@type number
  local widest_advance = 0
  for _, layout in ipairs(layouts) do
    widest_advance = math.max(widest_advance, layout.advance_width)
  end
  local canvas = coverage_rasterizer.create_canvas(
    math.ceil(widest_advance * scale) + CANVAS_PADDING_PIXELS,
    #lines * line_height
  )
  for line_index, layout in ipairs(layouts) do
    glyph_run_rasterizer.draw(canvas, face, layout.placements, {
      scale_x = scale,
      scale_y = scale,
      origin_x = 0,
      origin_y = ascent + (line_index - 1) * line_height,
    })
  end
  return coverage_rasterizer.to_bitmap(canvas)
end

---@param bitmap CoverageBitmapProps
---@param ink_width integer
---@param style_props TextArtStyleProps
---@param cell_size CellSizeProps
---@return GraphicsImageProps?
local function write_image(bitmap, ink_width, style_props, cell_size)
  ---@type GraphicsImageProps
  local image = {
    path = vim.fn.tempname() .. IMAGE_FILE_SUFFIX,
    width = round_up_to_multiple(ink_width, cell_size.width),
    height = round_up_to_multiple(bitmap.height, cell_size.height),
  }
  local file = io.open(image.path, WRITE_BINARY_MODE)
  if not file then return nil end
  file:write(
    graphics_pixel_encoder.encode_rgba(
      bitmap,
      ink_width,
      image.width,
      image.height,
      style_props.start_color,
      style_props.end_color
    )
  )
  file:close()
  return image
end

---@param text string
---@param style_props TextArtStyleProps
---@param width integer
---@param cell_size CellSizeProps
---@return GraphicsImageProps?
local function render_image(text, style_props, width, cell_size)
  local font_file = font_resolver.resolve(style_props.font)
  local face = font_file and font_face_loader.load(font_file)
  if not face then return nil end
  local point_size = style_props.line_height_cells
    * cell_size.height
    * LINE_HEIGHT_TO_POINT_SIZE
  local scale = point_size / face.units_per_em
  local lines =
    text_word_wrapper.wrap(face, text, width * cell_size.width / scale)
  if #lines == 0 then return nil end
  local bitmap = rasterize_lines(face, lines, scale)
  local ink_width = measure_ink_width(bitmap)
  if ink_width == NO_INK_WIDTH then return nil end
  return write_image(bitmap, ink_width, style_props, cell_size)
end

---@param image GraphicsImageProps
---@param cell_size CellSizeProps
---@return TextArtProps?
local function place_image(image, cell_size)
  local columns = math.ceil(image.width / cell_size.width)
  local rows = math.ceil(image.height / cell_size.height)
  if rows > graphics_placeholder_builder.max_rows() then
    os.remove(image.path)
    return nil
  end
  local image_id, highlight_group = graphics_image_registry.allocate()
  kitty_graphics_protocol.transmit_temporary_file(
    image_id,
    image.path,
    image.width,
    image.height,
    columns,
    rows
  )
  return {
    lines = graphics_placeholder_builder.build_lines(columns, rows),
    highlight = highlight_group,
  }
end

---@param text string
---@param style_props TextArtStyleProps
---@param width integer
---@return TextArtProps?
local function render(text, style_props, width)
  local cell_size = terminal_cell_size.resolve()
  local image = render_image(text, style_props, width, cell_size)
  return image and place_image(image, cell_size)
end

---@return boolean
function graphics_renderer.is_available()
  return font_resolver.is_available()
    and terminal_capability.supports_kitty_graphics()
end

---@param text string
---@param style_props TextArtStyleProps
---@param width integer
---@param on_done fun(art: TextArtProps?)
function graphics_renderer.render_async(text, style_props, width, on_done)
  vim.schedule(function()
    local ok, art = pcall(render, text, style_props, width)
    on_done(ok and art or nil)
  end)
end

return graphics_renderer
