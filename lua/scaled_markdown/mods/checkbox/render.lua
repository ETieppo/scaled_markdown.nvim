






local CHECKBOX_CAPTURE_ENUM =
require('scaled_markdown.mods.checkbox.checkbox_capture_enum')
local checkbox_highlight = require('scaled_markdown.mods.checkbox.highlight')



local checkbox_render = {}


function checkbox_render.render(
   capture_dto,
   mod_context_dto)

   local context_dto = mod_context_dto
   local is_checked = capture_dto.name == CHECKBOX_CAPTURE_ENUM.CHECKED
   local mod_config = context_dto.mod_config
   context_dto.writer.set_extmark(capture_dto.start_row, capture_dto.start_col, {
      end_row = capture_dto.end_row,
      end_col = capture_dto.end_col,
      conceal = is_checked and mod_config.checked_icon or
      mod_config.unchecked_icon,
      hl_group = is_checked and checkbox_highlight.GROUPS.CHECKED or
      checkbox_highlight.GROUPS.UNCHECKED,
   })
end

return checkbox_render
