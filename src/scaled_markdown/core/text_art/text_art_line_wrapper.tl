local utf8_text = require 'scaled_markdown.core.text.utf8_text'

local WORD_PATTERN <const> = '%S+'
local WORD_SEPARATOR <const> = ' '

local record text_art_line_wrapper
end

local function collect_words(text: string): {string}
  local words: {string} = {}
  for word in text:gmatch(WORD_PATTERN) do
    words[#words + 1] = word
  end
  return words
end

function text_art_line_wrapper.wrap(
  text: string,
  rendered_width: integer,
  available_width: integer
): {string}
  local columns_per_character = rendered_width
    / math.max(1, utf8_text.display_width(text))
  local wrapped_lines: {string} = {}
  local current_line: string = nil
  for _, word in ipairs(collect_words(text)) do
    local candidate_line = current_line
        and (current_line .. WORD_SEPARATOR .. word)
      or word
    local candidate_width = utf8_text.display_width(candidate_line)
      * columns_per_character
    if current_line and candidate_width > available_width then
      wrapped_lines[#wrapped_lines + 1] = current_line
      current_line = word
    else
      current_line = candidate_line
    end
  end
  if current_line then wrapped_lines[#wrapped_lines + 1] = current_line end
  return wrapped_lines
end

return text_art_line_wrapper
