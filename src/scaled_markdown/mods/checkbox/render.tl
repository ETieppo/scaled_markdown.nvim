local type CaptureProps = require 'scaled_markdown.core.types.capture_props'
local type CheckboxConfigProps =
  require 'scaled_markdown.mods.checkbox.config_props'
local type ModConfigProps =
  require 'scaled_markdown.core.types.mod_config_props'
local type RenderContextProps =
  require 'scaled_markdown.core.types.render_context_props'
local CHECKBOX_CAPTURE_ENUM =
  require 'scaled_markdown.mods.checkbox.checkbox_capture_enum'
local checkbox_highlight = require 'scaled_markdown.mods.checkbox.highlight'

local type CheckboxContextProps = RenderContextProps<CheckboxConfigProps>

local record checkbox_render
end

function checkbox_render.render(
  capture_dto: CaptureProps,
  mod_context_dto: RenderContextProps<ModConfigProps>
)
  local context_dto = mod_context_dto as CheckboxContextProps
  local is_checked = capture_dto.name == CHECKBOX_CAPTURE_ENUM.CHECKED
  local mod_config = context_dto.mod_config
  context_dto.writer.set_extmark(capture_dto.start_row, capture_dto.start_col, {
    end_row = capture_dto.end_row,
    end_col = capture_dto.end_col,
    conceal = is_checked and mod_config.checked_icon
      or mod_config.unchecked_icon,
    hl_group = is_checked and checkbox_highlight.GROUPS.CHECKED
      or checkbox_highlight.GROUPS.UNCHECKED,
  })
end

return checkbox_render
