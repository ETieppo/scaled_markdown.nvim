local outline_flattener =
  require 'scaled_markdown.core.raster.outline_flattener'

---@type RasterTransformProps
local FONT_UNIT_TRANSFORM =
  { scale_x = 1, scale_y = -1, origin_x = 0, origin_y = 0 }

---@class ink_bounds
local ink_bounds = {}

---@param face FontFaceProps
---@param placements GlyphPlacementProps[]
---@return InkBoundsProps?
function ink_bounds.measure(face, placements)
  ---@type InkBoundsProps?
  local bounds = nil
  ---@param x number
  ---@param y number
  local function include_point(x, y)
    if not bounds then
      bounds = { min_x = x, min_y = y, max_x = x, max_y = y }
      return
    end
    bounds.min_x = math.min(bounds.min_x, x)
    bounds.min_y = math.min(bounds.min_y, y)
    bounds.max_x = math.max(bounds.max_x, x)
    bounds.max_y = math.max(bounds.max_y, y)
  end
  for _, placement in ipairs(placements) do
    outline_flattener.flatten(
      face.load_outline(placement.glyph_index),
      placement.x,
      FONT_UNIT_TRANSFORM,
      ---@param start_x number
      ---@param start_y number
      ---@param end_x number
      ---@param end_y number
      function(start_x, start_y, end_x, end_y)
        include_point(start_x, start_y)
        include_point(end_x, end_y)
      end
    )
  end
  return bounds
end

return ink_bounds
