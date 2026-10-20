local DELIMITER_NODE_TYPE = 'latex_span_delimiter'
local DISPLAY_DELIMITER = '$$'
local ROW_SEPARATOR = '\n'
local BLANK_PATTERN = '^%s*$'
local CONTINUATION_PREFIX_PATTERN = '^[%s>]*'
local EDGE_WHITESPACE_PATTERN = '^%s'
local TRAILING_WHITESPACE_PATTERN = '%s$'
local DIGIT_PATTERN = '^%d$'
local LINE_PREFIX_ONLY_PATTERN = '^[%s>]*$'

---@class latex_block_dto_builder
local latex_block_dto_builder = {}

---@param node TSNode
---@return TSNode[]
local function collect_delimiters(node)
  ---@type TSNode[]
  local delimiters = {}
  for child in node:iter_children() do
    if child:type() == DELIMITER_NODE_TYPE then
      delimiters[#delimiters + 1] = child
    end
  end
  return delimiters
end

---@param node TSNode
---@return integer
local function measure_width(node)
  local _, start_col, _, end_col = node:range()
  return end_col - start_col
end

---@param capture_dto CaptureProps
---@param line_at fun(row: integer): string
---@return LatexRowSliceProps[]
local function build_row_slices(capture_dto, line_at)
  ---@type LatexRowSliceProps[]
  local row_slices = {}
  for row = capture_dto.start_row, capture_dto.end_row do
    local line = line_at(row)
    row_slices[#row_slices + 1] = {
      row = row,
      start_col = row == capture_dto.start_row and capture_dto.start_col
        or #line:match(CONTINUATION_PREFIX_PATTERN),
      end_col = row == capture_dto.end_row and capture_dto.end_col or #line,
    }
  end
  return row_slices
end

---@param row_slices LatexRowSliceProps[]
---@param line_at fun(row: integer): string
---@return string
local function join_row_slices(row_slices, line_at)
  ---@type string[]
  local slice_texts = {}
  for _, row_slice in ipairs(row_slices) do
    slice_texts[#slice_texts + 1] =
      line_at(row_slice.row):sub(row_slice.start_col + 1, row_slice.end_col)
  end
  return table.concat(slice_texts, ROW_SEPARATOR)
end

---@param row_slices LatexRowSliceProps[]
---@param opening_width integer
---@param line_at fun(row: integer): string
---@return integer anchor_row
---@return integer anchor_col
local function resolve_anchor(row_slices, opening_width, line_at)
  local first_slice = row_slices[1]
  local rest_of_opening_row = line_at(first_slice.row):sub(
    first_slice.start_col + opening_width + 1,
    first_slice.end_col
  )
  local anchor_slice = row_slices[2]
  if not rest_of_opening_row:match(BLANK_PATTERN) or not anchor_slice then
    return first_slice.row, first_slice.start_col
  end
  return anchor_slice.row, anchor_slice.start_col
end

---@param source string
---@param capture_dto CaptureProps
---@param line_at fun(row: integer): string
---@return boolean
local function is_inline_math(source, capture_dto, line_at)
  if source == '' then return false end
  if
    source:match(EDGE_WHITESPACE_PATTERN)
    or source:match(TRAILING_WHITESPACE_PATTERN)
  then
    return false
  end
  local following_character = line_at(capture_dto.end_row):sub(
    capture_dto.end_col + 1,
    capture_dto.end_col + 1
  )
  return not following_character:match(DIGIT_PATTERN)
end

---@param capture_dto CaptureProps
---@param line_at fun(row: integer): string
---@return boolean
local function is_standalone(capture_dto, line_at)
  local text_before =
    line_at(capture_dto.start_row):sub(1, capture_dto.start_col)
  local text_after = line_at(capture_dto.end_row):sub(capture_dto.end_col + 1)
  return text_before:match(LINE_PREFIX_ONLY_PATTERN) ~= nil
    and text_after:match(BLANK_PATTERN) ~= nil
end

---@param capture_dto CaptureProps
---@param line_at fun(row: integer): string
---@return LatexBlockProps?
function latex_block_dto_builder.build(capture_dto, line_at)
  local delimiters = collect_delimiters(capture_dto.node)
  if #delimiters < 2 then return nil end
  local opening_width = measure_width(delimiters[1])
  local closing_width = measure_width(delimiters[#delimiters])
  local is_display = opening_width == #DISPLAY_DELIMITER
  local row_slices = build_row_slices(capture_dto, line_at)
  local joined_text = join_row_slices(row_slices, line_at)
  local source =
    joined_text:sub(opening_width + 1, #joined_text - closing_width)
  if not is_display and not is_inline_math(source, capture_dto, line_at) then
    return nil
  end
  local anchor_row, anchor_col =
    resolve_anchor(row_slices, opening_width, line_at)
  return {
    is_display = is_display,
    is_standalone = is_standalone(capture_dto, line_at),
    source = source,
    row_slices = row_slices,
    anchor_row = anchor_row,
    anchor_col = anchor_col,
  }
end

return latex_block_dto_builder
