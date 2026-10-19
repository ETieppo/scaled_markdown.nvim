local BACKTICK_RUN_PATTERN = '`+'
local SURROUNDING_SPACE = ' '
local ONLY_SPACES_PATTERN = '^ *$'

---@class table_cell_parser
local table_cell_parser = {}

---@param segments TableCellSegmentProps[]
---@param text string
---@param is_code boolean
local function append_segment(segments, text, is_code)
  if text == '' then return end
  local last_segment = segments[#segments]
  if last_segment and last_segment.is_code == is_code then
    last_segment.text = last_segment.text .. text
  else
    segments[#segments + 1] = { text = text, is_code = is_code }
  end
end

---@param text string
---@param init integer
---@param run_length integer
---@return integer?, integer?
local function find_closing_run(text, init, run_length)
  local run_start, run_end = text:find(BACKTICK_RUN_PATTERN, init)
  while run_start do
    if run_end - run_start + 1 == run_length then return run_start, run_end end
    run_start, run_end = text:find(BACKTICK_RUN_PATTERN, run_end + 1)
  end
  return nil, nil
end

---@param code_text string
---@return string
local function strip_surrounding_space(code_text)
  local is_wrapped = #code_text >= 2
    and code_text:sub(1, 1) == SURROUNDING_SPACE
    and code_text:sub(-1) == SURROUNDING_SPACE
  if is_wrapped and not code_text:match(ONLY_SPACES_PATTERN) then
    return code_text:sub(2, -2)
  end
  return code_text
end

---@param segments TableCellSegmentProps[]
---@return string
local function join_segments(segments)
  ---@type string[]
  local texts = {}
  for index, segment in ipairs(segments) do
    texts[index] = segment.text
  end
  return table.concat(texts)
end

---@param source_text string
---@return TableCellProps
function table_cell_parser.parse(source_text)
  ---@type TableCellSegmentProps[]
  local segments = {}
  local plain_start = 1
  local run_start, run_end = source_text:find(BACKTICK_RUN_PATTERN)
  while run_start do
    local closing_start, closing_end =
      find_closing_run(source_text, run_end + 1, run_end - run_start + 1)
    if closing_start and closing_end then
      append_segment(
        segments,
        source_text:sub(plain_start, run_start - 1),
        false
      )
      append_segment(
        segments,
        strip_surrounding_space(source_text:sub(run_end + 1, closing_start - 1)),
        true
      )
      plain_start = closing_end + 1
      run_start, run_end = source_text:find(BACKTICK_RUN_PATTERN, plain_start)
    else
      run_start, run_end = source_text:find(BACKTICK_RUN_PATTERN, run_end + 1)
    end
  end
  append_segment(segments, source_text:sub(plain_start), false)
  return { text = join_segments(segments), segments = segments }
end

return table_cell_parser
