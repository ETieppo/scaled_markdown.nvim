local LINE_SEPARATOR = '\n'

---@class art_lines_parser
local art_lines_parser = {}

---@param line string
---@return boolean
local function is_blank(line) return line:match '^%s*$' ~= nil end

---@param stdout? string
---@return string[]
function art_lines_parser.split_lines(stdout)
  local lines = vim.split(stdout or '', LINE_SEPARATOR, { plain = true })
  if lines[#lines] == '' then table.remove(lines) end
  return lines
end

---@param lines string[]
---@return string[]
function art_lines_parser.trim_blank_edges(lines)
  local first_index, last_index = 1, #lines
  while first_index <= last_index and is_blank(lines[first_index]) do
    first_index = first_index + 1
  end
  while last_index >= first_index and is_blank(lines[last_index]) do
    last_index = last_index - 1
  end
  return vim.list_slice(lines, first_index, last_index)
end

---@param lines string[]
---@return TextArtProps?
function art_lines_parser.to_result(lines)
  return #lines > 0 and { lines = lines } or nil
end

return art_lines_parser
