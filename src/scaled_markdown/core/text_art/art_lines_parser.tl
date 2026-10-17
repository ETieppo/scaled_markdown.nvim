local type TextArtProps = require 'scaled_markdown.core.types.text_art_props'

local LINE_SEPARATOR <const> = '\n'

local record art_lines_parser
end

local function is_blank(
  line: string
): boolean return line:match '^%s*$' ~= nil end

function art_lines_parser.split_lines(stdout: string): {string}
  local lines = vim.split(stdout or '', LINE_SEPARATOR, { plain = true })
  if lines[#lines] == '' then table.remove(lines) end
  return lines
end

function art_lines_parser.trim_blank_edges(lines: {string}): {string}
  local first_index, last_index = 1, #lines
  while first_index <= last_index and is_blank(lines[first_index]) do
    first_index = first_index + 1
  end
  while last_index >= first_index and is_blank(lines[last_index]) do
    last_index = last_index - 1
  end
  return vim.list_slice(lines, first_index, last_index)
end

function art_lines_parser.to_result(lines: {string}): TextArtProps
  return #lines > 0 and { lines = lines } or nil
end

return art_lines_parser
