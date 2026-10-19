local utf8_text = require 'scaled_markdown.core.text.utf8_text'

---@class text_line_layout
local text_line_layout = {}

---@param face FontFaceProps
---@param text string
---@return TextLineLayoutProps
function text_line_layout.layout(face, text)
  ---@type GlyphPlacementProps[]
  local placements = {}
  local pen_x = 0.0
  ---@type integer?
  local previous_glyph_index = nil
  for _, codepoint in ipairs(utf8_text.codepoints(text)) do
    local glyph_index = face.find_glyph_index(codepoint)
    if previous_glyph_index then
      pen_x = pen_x + face.kerning(previous_glyph_index, glyph_index)
    end
    placements[#placements + 1] = { glyph_index = glyph_index, x = pen_x }
    pen_x = pen_x + face.advance_width(glyph_index)
    previous_glyph_index = glyph_index
  end
  return { placements = placements, advance_width = pen_x }
end

return text_line_layout
