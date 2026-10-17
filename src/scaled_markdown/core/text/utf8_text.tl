local CHARACTER_SPLIT_PATTERN <const> = '\\zs'

local record utf8_text
end

function utf8_text.split_characters(text: string): {string}
  return vim.fn.split(text, CHARACTER_SPLIT_PATTERN)
end

function utf8_text.display_width(
  text: string
): integer return vim.fn.strdisplaywidth(text) end

function utf8_text.pad_right(text: string, width: integer): string
  return text
    .. string.rep(' ', math.max(0, width - utf8_text.display_width(text)))
end

function utf8_text.pad_left(text: string, width: integer): string
  return string.rep(' ', math.max(0, width - utf8_text.display_width(text)))
    .. text
end

function utf8_text.pad_center(text: string, width: integer): string
  local free_width = math.max(0, width - utf8_text.display_width(text))
  local left_width = math.floor(free_width / 2)
  return string.rep(' ', left_width)
    .. text
    .. string.rep(' ', free_width - left_width)
end

function utf8_text.trim(text: string): string return vim.trim(text) end

return utf8_text
