local LATEX_COLUMN_ALIGNMENT_ENUM =
  require 'scaled_markdown.mods.latex.latex_column_alignment_enum'
local utf8_text = require 'scaled_markdown.core.text.utf8_text'

---@class latex_box
local latex_box = {}

---@param width integer
---@return string
local function blank_line(width) return string.rep(' ', width) end

---@param box LatexBoxProps
---@return integer
local function ascent_of(box) return box.baseline - 1 end

---@param box LatexBoxProps
---@return integer
local function descent_of(box) return #box.lines - box.baseline end

---@param text string
---@return LatexBoxProps
function latex_box.from_text(text)
  return {
    lines = { text },
    width = utf8_text.display_width(text),
    baseline = 1,
  }
end

---@return LatexBoxProps
function latex_box.empty() return latex_box.from_text '' end

---@param width integer
---@return LatexBoxProps
function latex_box.blank(width) return latex_box.from_text(blank_line(width)) end

---@param line string
---@param width integer
---@param alignment LatexColumnAlignmentEnum
---@return string
local function align_line(line, width, alignment)
  if alignment == LATEX_COLUMN_ALIGNMENT_ENUM.RIGHT then
    return utf8_text.pad_left(line, width)
  end
  if alignment == LATEX_COLUMN_ALIGNMENT_ENUM.CENTER then
    return utf8_text.pad_center(line, width)
  end
  return utf8_text.pad_right(line, width)
end

---@param box LatexBoxProps
---@param width integer
---@param alignment LatexColumnAlignmentEnum
---@return LatexBoxProps
function latex_box.align(box, width, alignment)
  ---@type string[]
  local lines = {}
  for line_index, line in ipairs(box.lines) do
    lines[line_index] = align_line(line, width, alignment)
  end
  return {
    lines = lines,
    width = math.max(width, box.width),
    baseline = box.baseline,
  }
end

---@param boxes LatexBoxProps[]
---@return LatexBoxProps
function latex_box.join_horizontal(boxes)
  if #boxes == 0 then return latex_box.empty() end
  local ascent, descent, width = 0, 0, 0
  for _, box in ipairs(boxes) do
    ascent = math.max(ascent, ascent_of(box))
    descent = math.max(descent, descent_of(box))
    width = width + box.width
  end
  ---@type string[]
  local lines = {}
  for line_index = 1, ascent + descent + 1 do
    ---@type string[]
    local parts = {}
    for _, box in ipairs(boxes) do
      local box_line_index = line_index - (ascent - ascent_of(box))
      parts[#parts + 1] = box.lines[box_line_index] or blank_line(box.width)
    end
    lines[line_index] = table.concat(parts)
  end
  return { lines = lines, width = width, baseline = ascent + 1 }
end

---@param boxes LatexBoxProps[]
---@param baseline integer
---@param alignment LatexColumnAlignmentEnum
---@return LatexBoxProps
function latex_box.stack(boxes, baseline, alignment)
  local width = 0
  for _, box in ipairs(boxes) do
    width = math.max(width, box.width)
  end
  ---@type string[]
  local lines = {}
  for _, box in ipairs(boxes) do
    for _, line in ipairs(box.lines) do
      lines[#lines + 1] = align_line(line, width, alignment)
    end
  end
  return { lines = lines, width = width, baseline = baseline }
end

---@param placements LatexScriptPlacementProps[]
---@return LatexBoxProps
function latex_box.place_vertically(placements)
  local top, bottom, width = 0, 0, 0
  for _, placement in ipairs(placements) do
    top = math.max(top, placement.shift + ascent_of(placement.box))
    bottom = math.max(bottom, descent_of(placement.box) - placement.shift)
    width = math.max(width, placement.box.width)
  end
  ---@type string[]
  local lines = {}
  for line_index = 1, top + bottom + 1 do
    lines[line_index] = blank_line(width)
  end
  for _, placement in ipairs(placements) do
    local first_line_index = top
      + 1
      - placement.shift
      - ascent_of(placement.box)
    for offset, line in ipairs(placement.box.lines) do
      lines[first_line_index + offset - 1] = utf8_text.pad_right(line, width)
    end
  end
  return { lines = lines, width = width, baseline = top + 1 }
end

return latex_box
