local type CaptureProps = require 'scaled_markdown.core.types.capture_props'
local type ModConfigProps =
  require 'scaled_markdown.core.types.mod_config_props'
local type RenderContextProps =
  require 'scaled_markdown.core.types.render_context_props'
local type ThematicBreakConfigProps =
  require 'scaled_markdown.mods.thematic_break.config_props'
local gradient_chunks = require 'scaled_markdown.core.highlight.gradient_chunks'

local type ThematicBreakContextProps =
  RenderContextProps<ThematicBreakConfigProps>

local record thematic_break_render
end

function thematic_break_render.render(
  capture_dto: CaptureProps,
  mod_context_dto: RenderContextProps<ModConfigProps>
)
  local context_dto = mod_context_dto as ThematicBreakContextProps
  local line_width =
    math.max(1, context_dto.text_area_width - capture_dto.start_col)
  local line_text = string.rep(context_dto.mod_config.character, line_width)
  context_dto.writer.set_extmark(capture_dto.start_row, capture_dto.start_col, {
    virt_text = gradient_chunks.from_text(line_text),
    virt_text_pos = 'overlay',
  })
end

return thematic_break_render
