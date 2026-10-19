local TEXT_CAPTURE_ENUM = require 'scaled_markdown.mods.text.text_capture_enum'
local text_highlight = require 'scaled_markdown.mods.text.highlight'

---@type table<string, string>
local HIGHLIGHT_GROUP_BY_CAPTURE = {
  [TEXT_CAPTURE_ENUM.EMPHASIS] = text_highlight.GROUPS.EMPHASIS,
  [TEXT_CAPTURE_ENUM.STRONG_EMPHASIS] = text_highlight.GROUPS.STRONG_EMPHASIS,
  [TEXT_CAPTURE_ENUM.STRIKETHROUGH] = text_highlight.GROUPS.STRIKETHROUGH,
}

---@alias TextContextProps RenderContextProps<TextConfigProps>

---@class text_render
local text_render = {}

---@param capture_dto CaptureProps
---@param mod_context_dto RenderContextProps<ModConfigProps>
function text_render.render(capture_dto, mod_context_dto)
  ---@type TextContextProps
  local context_dto = mod_context_dto
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
