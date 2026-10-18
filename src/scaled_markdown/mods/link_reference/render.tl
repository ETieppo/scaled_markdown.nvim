local type CaptureProps = require 'scaled_markdown.core.types.capture_props'
local type ModConfigProps =
  require 'scaled_markdown.core.types.mod_config_props'
local type RenderContextProps =
  require 'scaled_markdown.core.types.render_context_props'
local type LinkReferenceConfigProps =
  require 'scaled_markdown.mods.link_reference.config_props'
local link_reference_highlight =
  require 'scaled_markdown.mods.link_reference.highlight'

local HIGHLIGHT_GROUP_BY_NODE_TYPE <const>: {string: string} = {
  link_label = link_reference_highlight.GROUPS.LABEL,
  link_destination = link_reference_highlight.GROUPS.DESTINATION,
  link_title = link_reference_highlight.GROUPS.TITLE,
}

local type LinkReferenceContextProps =
  RenderContextProps<LinkReferenceConfigProps>

local record link_reference_render
end

function link_reference_render.render(
  capture_dto: CaptureProps,
  mod_context_dto: RenderContextProps<ModConfigProps>
)
  local context_dto = mod_context_dto as LinkReferenceContextProps
  local writer = context_dto.writer
  writer.set_extmark(capture_dto.start_row, capture_dto.start_col, {
    virt_text = {
      { context_dto.mod_config.icon, link_reference_highlight.GROUPS.ICON },
    },
    virt_text_pos = 'inline',
  })
  for child in capture_dto.node:iter_children() do
    local highlight_group = HIGHLIGHT_GROUP_BY_NODE_TYPE[child:type()]
    if highlight_group then
      local start_row, start_col, end_row, end_col = child:range()
      writer.set_extmark(start_row, start_col, {
        end_row = end_row,
        end_col = end_col,
        hl_group = highlight_group,
      })
    end
  end
end

return link_reference_render
