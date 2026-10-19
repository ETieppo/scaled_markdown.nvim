local coverage_rasterizer =
  require 'scaled_markdown.core.raster.coverage_rasterizer'
local outline_flattener =
  require 'scaled_markdown.core.raster.outline_flattener'

---@class glyph_run_rasterizer
local glyph_run_rasterizer = {}

---@param canvas RasterCanvasProps
---@param face FontFaceProps
---@param placements GlyphPlacementProps[]
---@param transform RasterTransformProps
function glyph_run_rasterizer.draw(canvas, face, placements, transform)
  ---@param start_x number
  ---@param start_y number
  ---@param end_x number
  ---@param end_y number
  local function draw_line(start_x, start_y, end_x, end_y)
    coverage_rasterizer.draw_line(canvas, start_x, start_y, end_x, end_y)
  end
  for _, placement in ipairs(placements) do
    outline_flattener.flatten(
      face.load_outline(placement.glyph_index),
      placement.x,
      transform,
      draw_line
    )
  end
end

---@param face FontFaceProps
---@param placements GlyphPlacementProps[]
---@param transform RasterTransformProps
---@param width integer
---@param height integer
---@return CoverageBitmapProps
function glyph_run_rasterizer.rasterize(
  face,
  placements,
  transform,
  width,
  height
)
  local canvas = coverage_rasterizer.create_canvas(width, height)
  glyph_run_rasterizer.draw(canvas, face, placements, transform)
  return coverage_rasterizer.to_bitmap(canvas)
end

return glyph_run_rasterizer
