local SYMBOL_CELL_GEOMETRY =
  require 'scaled_markdown.core.symbolize.symbol_cell_geometry'
local art_lines_parser =
  require 'scaled_markdown.core.text_art.art_lines_parser'
local font_face_loader = require 'scaled_markdown.core.font.font_face_loader'
local font_resolver = require 'scaled_markdown.core.text_art.font_resolver'
local glyph_run_rasterizer =
  require 'scaled_markdown.core.raster.glyph_run_rasterizer'
local ink_bounds = require 'scaled_markdown.core.raster.ink_bounds'
local symbol_art_builder =
  require 'scaled_markdown.core.symbolize.symbol_art_builder'
local symbol_catalog = require 'scaled_markdown.core.symbolize.symbol_catalog'
local symbol_grid_fitter =
  require 'scaled_markdown.core.symbolize.symbol_grid_fitter'
local text_line_layout = require 'scaled_markdown.core.layout.text_line_layout'
local typeface_glyph_box =
  require 'scaled_markdown.core.text_art.typeface_glyph_box'

local HORIZONTAL_MARGIN_EM = 0.025

---@class typeface_renderer: TextArtRendererProps
local typeface_renderer = {}

---@param glyph_box GlyphBoxProps
---@param bounds InkBoundsProps
---@param margin number
---@param image_width number
---@param grid SymbolGridProps
---@return RasterTransformProps
local function build_transform(glyph_box, bounds, margin, image_width, grid)
  local scale_x = grid.columns
    * SYMBOL_CELL_GEOMETRY.SUBCELL_COLUMNS
    / image_width
  local scale_y = grid.rows
    * SYMBOL_CELL_GEOMETRY.SUBCELL_ROWS
    / glyph_box.height
  return {
    scale_x = scale_x,
    scale_y = scale_y,
    origin_x = (margin - bounds.min_x) * scale_x,
    origin_y = glyph_box.top * scale_y,
  }
end

---@param face FontFaceProps
---@param text string
---@param style_props TextArtStyleProps
---@param width integer
---@return TextArtProps?
local function render_with_face(face, text, style_props, width)
  local glyph_box = typeface_glyph_box.resolve(face)
  if not glyph_box then return nil end
  local placements = text_line_layout.layout(face, text).placements
  local bounds = ink_bounds.measure(face, placements)
  if not bounds then return nil end
  local margin = face.units_per_em * HORIZONTAL_MARGIN_EM
  local image_width = bounds.max_x - bounds.min_x + 2 * margin
  local grid = symbol_grid_fitter.fit(
    image_width,
    glyph_box.height,
    style_props.rows,
    width
  )
  local bitmap = glyph_run_rasterizer.rasterize(
    face,
    placements,
    build_transform(glyph_box, bounds, margin, image_width, grid),
    grid.columns * SYMBOL_CELL_GEOMETRY.SUBCELL_COLUMNS,
    grid.rows * SYMBOL_CELL_GEOMETRY.SUBCELL_ROWS
  )
  return art_lines_parser.to_result(
    symbol_art_builder.build(
      bitmap,
      grid,
      symbol_catalog.resolve(style_props.symbols)
    )
  )
end

---@param text string
---@param style_props TextArtStyleProps
---@param width integer
---@return TextArtProps?
local function render(text, style_props, width)
  local font_file = font_resolver.resolve(style_props.font)
  local face = font_file and font_face_loader.load(font_file)
  if not face then return nil end
  return render_with_face(face, text, style_props, width)
end

---@return boolean
function typeface_renderer.is_available() return font_resolver.is_available() end

---@param text string
---@param style_props TextArtStyleProps
---@param width integer
---@param on_done fun(art: TextArtProps?)
function typeface_renderer.render_async(text, style_props, width, on_done)
  vim.schedule(function()
    local ok, art = pcall(render, text, style_props, width)
    on_done(ok and art or nil)
  end)
end

return typeface_renderer
