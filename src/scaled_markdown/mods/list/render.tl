local type CaptureProps = require 'scaled_markdown.core.types.capture_props'
local type ModConfigProps =
  require 'scaled_markdown.core.types.mod_config_props'
local type RenderContextProps =
  require 'scaled_markdown.core.types.render_context_props'
local type ListConfigProps = require 'scaled_markdown.mods.list.config_props'
local LIST_CAPTURE_ENUM = require 'scaled_markdown.mods.list.list_capture_enum'
local list_highlight = require 'scaled_markdown.mods.list.highlight'

local LIST_NODE_TYPE <const> = 'list'
local BULLET_CHARACTER_PATTERN <const> = '[-+*]'

local type ListContextProps = RenderContextProps<ListConfigProps>

local record list_render
end

local function count_list_depth(node: vim.TSNodeProps): integer
  local depth = 0
  local ancestor = node:parent()
  while ancestor do
    if ancestor:type() == LIST_NODE_TYPE then depth = depth + 1 end
    ancestor = ancestor:parent()
  end
  return math.max(1, depth)
end

local function render_bullet(
  capture_dto: CaptureProps,
  context_dto: ListContextProps
)
  local bullet_offset = capture_dto.text:find(BULLET_CHARACTER_PATTERN)
  if not bullet_offset then return end
  local bullets = context_dto.mod_config.bullets
  local bullet =
    bullets[(count_list_depth(capture_dto.node) - 1) % #bullets + 1]
  context_dto.writer.set_extmark(
    capture_dto.start_row,
    capture_dto.start_col + bullet_offset - 1,
    {
      virt_text = { { bullet, list_highlight.GROUPS.BULLET } },
      virt_text_pos = 'overlay',
    }
  )
end

function list_render.render(
  capture_dto: CaptureProps,
  mod_context_dto: RenderContextProps<ModConfigProps>
)
  local context_dto = mod_context_dto as ListContextProps
  if capture_dto.name == LIST_CAPTURE_ENUM.BULLET then
    render_bullet(capture_dto, context_dto)
    return
  end
  context_dto.writer.set_extmark(capture_dto.start_row, capture_dto.start_col, {
    end_row = capture_dto.end_row,
    end_col = capture_dto.end_col,
    hl_group = list_highlight.GROUPS.ORDERED,
  })
end

return list_render
