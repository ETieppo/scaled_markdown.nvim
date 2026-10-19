local LIST_CAPTURE_ENUM = require 'scaled_markdown.mods.list.list_capture_enum'

local LIST_QUERY = ([[
(list_marker_minus) @%s
(list_marker_plus) @%s
(list_marker_star) @%s
(list_marker_dot) @%s
(list_marker_parenthesis) @%s
]]):format(
  LIST_CAPTURE_ENUM.BULLET,
  LIST_CAPTURE_ENUM.BULLET,
  LIST_CAPTURE_ENUM.BULLET,
  LIST_CAPTURE_ENUM.ORDERED,
  LIST_CAPTURE_ENUM.ORDERED
)

return LIST_QUERY
