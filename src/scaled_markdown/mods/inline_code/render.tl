local type CaptureProps = require 'scaled_markdown.core.types.capture_props'
local type ModConfigProps =
  require 'scaled_markdown.core.types.mod_config_props'
local type RenderContextProps =
  require 'scaled_markdown.core.types.render_context_props'
local type InlineCodeConfigProps =
  require 'scaled_markdown.mods.inline_code.config_props'
local INLINE_CODE_CAPTURE_ENUM =
  require 'scaled_markdown.mods.inline_code.inline_code_capture_enum'
local inline_code_highlight =
  require 'scaled_markdown.mods.inline_code.highlight'

local type InlineCodeContextProps = RenderContextProps<InlineCodeConfigProps>

local record inline_code_render
end

function inline_code_render.render(
  capture_dto: CaptureProps,
  mod_context_dto: RenderContextProps<ModConfigProps>
)
  local context_dto = mod_context_dto as InlineCodeContextProps
  local extmark_options: vim.ExtmarkOptionsProps = {
    end_row = capture_dto.end_row,
    end_col = capture_dto.end_col,
  }
  if capture_dto.name == INLINE_CODE_CAPTURE_ENUM.DELIMITER then
    extmark_options.conceal = context_dto.mod_config.delimiter_replacement
  else
    extmark_options.hl_group = inline_code_highlight.GROUPS.CODE_SPAN
  end
  context_dto.writer.set_extmark(
    capture_dto.start_row,
    capture_dto.start_col,
    extmark_options
  )
end

return inline_code_render
