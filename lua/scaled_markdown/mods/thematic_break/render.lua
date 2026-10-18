






local gradient_chunks = require('scaled_markdown.core.highlight.gradient_chunks')




local thematic_break_render = {}


function thematic_break_render.render(
   capture_dto,
   mod_context_dto)

   local context_dto = mod_context_dto
   local line_width =
   math.max(1, context_dto.text_area_width - capture_dto.start_col)
   local line_text = string.rep(context_dto.mod_config.character, line_width)
   context_dto.writer.set_extmark(capture_dto.start_row, capture_dto.start_col, {
      virt_text = gradient_chunks.from_text(line_text),
      virt_text_pos = 'overlay',
   })
end

return thematic_break_render
