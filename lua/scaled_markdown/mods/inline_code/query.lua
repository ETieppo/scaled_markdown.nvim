local INLINE_CODE_CAPTURE_ENUM =
require('scaled_markdown.mods.inline_code.inline_code_capture_enum')

local INLINE_CODE_QUERY = ([[
(code_span) @%s
(code_span_delimiter) @%s
]]):format(
INLINE_CODE_CAPTURE_ENUM.CODE_SPAN,
INLINE_CODE_CAPTURE_ENUM.DELIMITER)


return INLINE_CODE_QUERY
