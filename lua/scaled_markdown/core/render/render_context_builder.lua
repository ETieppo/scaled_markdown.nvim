local window_geometry = require 'scaled_markdown.core.render.window_geometry'

---@class render_context_builder
local render_context_builder = {}

---@param buf integer
---@param win integer
---@param writer ExtmarkWriterProps
---@return RenderContextProps<ModConfigProps>
function render_context_builder.build(buf, win, writer)
  return {
    buf = buf,
    win = win,
    writer = writer,
    text_area_width = window_geometry.text_area_width(win),
    line_at = function(row)
      return vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ''
    end,
    decorate_line_prefix = function() return {} end,
  }
end

---@param base_context_dto RenderContextProps<ModConfigProps>
---@param mod_config ModConfigProps
---@return RenderContextProps<ModConfigProps>
function render_context_builder.with_mod_config(
  base_context_dto,
  mod_config
)
  return {
    buf = base_context_dto.buf,
    win = base_context_dto.win,
    writer = base_context_dto.writer,
    text_area_width = base_context_dto.text_area_width,
    line_at = base_context_dto.line_at,
    decorate_line_prefix = base_context_dto.decorate_line_prefix,
    mod_config = mod_config,
  }
end

return render_context_builder
