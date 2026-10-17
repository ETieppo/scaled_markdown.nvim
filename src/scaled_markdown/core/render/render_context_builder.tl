local type ExtmarkWriterProps =
  require 'scaled_markdown.core.types.extmark_writer_props'
local type ModConfigProps =
  require 'scaled_markdown.core.types.mod_config_props'
local type RenderContextProps =
  require 'scaled_markdown.core.types.render_context_props'
local window_geometry = require 'scaled_markdown.core.render.window_geometry'

local record render_context_builder
end

function render_context_builder.build(
  buf: integer,
  win: integer,
  writer: ExtmarkWriterProps
): RenderContextProps<ModConfigProps>
  return {
    buf = buf,
    win = win,
    writer = writer,
    text_area_width = window_geometry.text_area_width(win),
    line_at = function(row: integer): string
      return vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ''
    end,
  }
end

function render_context_builder.with_mod_config(
  base_context_dto: RenderContextProps<ModConfigProps>,
  mod_config: ModConfigProps
): RenderContextProps<ModConfigProps>
  return {
    buf = base_context_dto.buf,
    win = base_context_dto.win,
    writer = base_context_dto.writer,
    text_area_width = base_context_dto.text_area_width,
    line_at = base_context_dto.line_at,
    mod_config = mod_config,
  }
end

return render_context_builder
