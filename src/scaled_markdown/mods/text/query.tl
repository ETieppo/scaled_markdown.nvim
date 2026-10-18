local TEXT_CAPTURE_ENUM = require 'scaled_markdown.mods.text.text_capture_enum'

local TEXT_QUERY <const> = ([[
(emphasis) @%s
(strong_emphasis) @%s
(strikethrough) @%s
(emphasis_delimiter) @%s
]]):format(
  TEXT_CAPTURE_ENUM.EMPHASIS,
  TEXT_CAPTURE_ENUM.STRONG_EMPHASIS,
  TEXT_CAPTURE_ENUM.STRIKETHROUGH,
  TEXT_CAPTURE_ENUM.DELIMITER
)

return TEXT_QUERY
