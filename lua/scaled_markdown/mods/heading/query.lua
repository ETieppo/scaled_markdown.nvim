local HEADING_CAPTURE_ENUM =
require('scaled_markdown.mods.heading.heading_capture_enum')

local HEADING_QUERY = ([[
(atx_heading) @%s
(setext_heading) @%s
]]):format(
HEADING_CAPTURE_ENUM.ATX_HEADING,
HEADING_CAPTURE_ENUM.SETEXT_HEADING)


return HEADING_QUERY
