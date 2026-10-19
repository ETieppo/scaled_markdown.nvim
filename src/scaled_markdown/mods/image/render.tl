local type CaptureProps = require 'scaled_markdown.core.types.capture_props'
local type ModConfigProps =
  require 'scaled_markdown.core.types.mod_config_props'
local type RenderContextProps =
  require 'scaled_markdown.core.types.render_context_props'
local type ImageConfigProps = require 'scaled_markdown.mods.image.config_props'
local image_highlight = require 'scaled_markdown.mods.image.highlight'

local IMAGE_DESCRIPTION_NODE_TYPE <const> = 'image_description'

local type ImageContextProps = RenderContextProps<ImageConfigProps>

local record image_render
end

local function find_description_node(
  image_node: vim.TSNodeProps
): vim.TSNodeProps
  for child in image_node:iter_children() do
    if child:type() == IMAGE_DESCRIPTION_NODE_TYPE then return child end
  end
  return nil
end

function image_render.render(
  capture_dto: CaptureProps,
  mod_context_dto: RenderContextProps<ModConfigProps>
)
  local context_dto = mod_context_dto as ImageContextProps
  local description_node = find_description_node(capture_dto.node)
  if not description_node then return end
  local writer = context_dto.writer
  local description_start_row, description_start_col, description_end_row, description_end_col =
    description_node:range()
  writer.set_extmark(capture_dto.start_row, capture_dto.start_col, {
    virt_text = { { context_dto.mod_config.icon, image_highlight.GROUPS.ICON } },
    virt_text_pos = 'inline',
  })
  writer.set_extmark(capture_dto.start_row, capture_dto.start_col, {
    end_row = description_start_row,
    end_col = description_start_col,
    conceal = '',
  })
  writer.set_extmark(description_start_row, description_start_col, {
    end_row = description_end_row,
    end_col = description_end_col,
    hl_group = image_highlight.GROUPS.DESCRIPTION,
  })
  writer.set_extmark(description_end_row, description_end_col, {
    end_row = capture_dto.end_row,
    end_col = capture_dto.end_col,
    conceal = '',
  })
end

return image_render
