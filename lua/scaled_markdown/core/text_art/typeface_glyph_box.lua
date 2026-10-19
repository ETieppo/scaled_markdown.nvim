local ink_bounds = require 'scaled_markdown.core.raster.ink_bounds'
local text_line_layout = require 'scaled_markdown.core.layout.text_line_layout'

local GLYPH_BOX_REFERENCE_TEXT = 'Hbdfgjklpqy'
local UNMEASURED_BOX_MARKER = false

---@class typeface_glyph_box
local typeface_glyph_box = {}

---@type table<FontFaceProps, GlyphBoxProps|boolean>
local glyph_box_by_face = setmetatable({}, { __mode = 'k' })

---@param face FontFaceProps
---@return GlyphBoxProps?
local function measure(face)
  local bounds = ink_bounds.measure(
    face,
    text_line_layout.layout(face, GLYPH_BOX_REFERENCE_TEXT).placements
  )
  if not bounds then return nil end
  local bottom = math.max(bounds.min_y, face.descender)
  if bounds.max_y <= bottom then return nil end
  return { top = bounds.max_y, height = bounds.max_y - bottom }
end

---@param face FontFaceProps
---@return GlyphBoxProps?
function typeface_glyph_box.resolve(face)
  if glyph_box_by_face[face] == nil then
    glyph_box_by_face[face] = measure(face) or UNMEASURED_BOX_MARKER
  end
  local glyph_box = glyph_box_by_face[face]
  return type(glyph_box) == 'table' and glyph_box or nil
end

return typeface_glyph_box
