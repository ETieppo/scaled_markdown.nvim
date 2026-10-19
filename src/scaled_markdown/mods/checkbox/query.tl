local CHECKBOX_CAPTURE_ENUM =
  require 'scaled_markdown.mods.checkbox.checkbox_capture_enum'

local CHECKBOX_QUERY <const> = ([[
(task_list_marker_unchecked) @%s
(task_list_marker_checked) @%s
]]):format(CHECKBOX_CAPTURE_ENUM.UNCHECKED, CHECKBOX_CAPTURE_ENUM.CHECKED)

return CHECKBOX_QUERY
