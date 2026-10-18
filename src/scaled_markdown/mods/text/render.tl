local type CaptureProps = require 'scaled_markdown.core.types.capture_props'
local type ModConfigProps =
  require 'scaled_markdown.core.types.mod_config_props'
local type RenderContextProps =
  require 'scaled_markdown.core.types.render_context_props'
local type TextConfigProps = require 'scaled_markdown.mods.text.config_props'
local TEXT_CAPTURE_ENUM = require 'scaled_markdown.mods.text.text_capture_enum'
local text_highlight = require 'scaled_markdown.mods.text.highlight'

local HIGHLIGHT_GROUP_BY_CAPTURE <const>: {string: string} = {
  [TEXT_CAPTURE_ENUM.EMPHASIS] = text_highlight.GROUPS.EMPHASIS,
  [TEXT_CAPTURE_ENUM.STRONG_EMPHASIS] = text_highlight.GROUPS.STRONG_EMPHASIS,
  [TEXT_CAPTURE_ENUM.STRIKETHROUGH] = text_highlight.GROUPS.STRIKETHROUGH,
}

local type TextContextProps = RenderContextProps<TextConfigProps>

local record text_render
end

function text_render.render(
  capture_dto: CaptureProps,
  mod_context_dto: RenderContextProps<ModConfigProps>
)
  local context_dto = mod_context_dto as TextContextProps
  if capture_dto.name == TEXT_CAPTURE_ENUM.DELIMITER then
    if context_dto.mod_config.conceal_delimiters then
      context_dto.writer.set_extmark(
        capture_dto.start_row,
        capture_dto.start_col,
        {
          end_row = capture_dto.end_row,
          end_col = capture_dto.end_col,
          conceal = '',
        }
      )
    end
    return
  end
  context_dto.writer.set_extmark(capture_dto.start_row, capture_dto.start_col, {
    end_row = capture_dto.end_row,
    end_col = capture_dto.end_col,
    hl_group = HIGHLIGHT_GROUP_BY_CAPTURE[capture_dto.name],
  })
end

return text_render
