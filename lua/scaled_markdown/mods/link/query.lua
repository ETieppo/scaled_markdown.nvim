local LINK_CAPTURE_ENUM = require 'scaled_markdown.mods.link.link_capture_enum'

local LINK_QUERY = ([[
(inline_link) @%s
(full_reference_link) @%s
(uri_autolink) @%s
]]):format(
  LINK_CAPTURE_ENUM.LABELED_LINK,
  LINK_CAPTURE_ENUM.LABELED_LINK,
  LINK_CAPTURE_ENUM.AUTOLINK
)

return LINK_QUERY
