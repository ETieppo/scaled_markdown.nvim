local gradient_palette =
  require 'scaled_markdown.core.highlight.gradient_palette'
local utf8_text = require 'scaled_markdown.core.text.utf8_text'

---@class gradient_chunks
local gradient_chunks = {}

---@param chunks [string, string][]
---@param text string
---@param highlight string
local function append_chunk(chunks, text, highlight)
  local last_chunk = chunks[#chunks]
  if last_chunk and last_chunk[2] == highlight then
    last_chunk[1] = last_chunk[1] .. text
  else
    chunks[#chunks + 1] = { text, highlight }
  end
end

---@param segments GradientSegmentProps[]
---@return integer
local function measure_segments(segments)
  local total_width = 0
  for _, segment in ipairs(segments) do
    total_width = total_width + utf8_text.display_width(segment.text)
  end
  return total_width
end

---@param segments GradientSegmentProps[]
---@param gradient_width? integer
---@return [string, string][]
function gradient_chunks.from_segments(segments, gradient_width)
  local total_width = gradient_width or measure_segments(segments)
  ---@type [string, string][]
  local chunks = {}
  local column = 0
  for _, segment in ipairs(segments) do
    if segment.highlight then
      append_chunk(chunks, segment.text, segment.highlight)
      column = column + utf8_text.display_width(segment.text)
    else
      for _, character in ipairs(utf8_text.split_characters(segment.text)) do
        local highlight_group = gradient_palette.group_for_position(
          column,
          total_width,
          segment.variant
        )
        append_chunk(chunks, character, highlight_group)
        column = column + utf8_text.display_width(character)
      end
    end
  end
  return chunks
end

---@param text string
---@param gradient_width? integer
---@return [string, string][]
function gradient_chunks.from_text(text, gradient_width)
  return gradient_chunks.from_segments({ { text = text } }, gradient_width)
end

return gradient_chunks
