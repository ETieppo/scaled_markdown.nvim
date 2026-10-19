local INLINE_CODE_CAPTURE_ENUM =
  require 'scaled_markdown.mods.inline_code.inline_code_capture_enum'
local inline_code_highlight =
  require 'scaled_markdown.mods.inline_code.highlight'

---@alias InlineCodeContextProps RenderContextProps<InlineCodeConfigProps>

---@class inline_code_render
local inline_code_render = {}

---@param capture_dto CaptureProps
---@param mod_context_dto RenderContextProps<ModConfigProps>
function inline_code_render.render(capture_dto, mod_context_dto)
  ---@type InlineCodeContextProps
  local context_dto = mod_context_dto
  ---@type vim.api.keyset.set_extmark
  local extmark_options = {
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
