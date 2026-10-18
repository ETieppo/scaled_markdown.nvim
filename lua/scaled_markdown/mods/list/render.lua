





local LIST_CAPTURE_ENUM = require('scaled_markdown.mods.list.list_capture_enum')
local list_highlight = require('scaled_markdown.mods.list.highlight')

local LIST_NODE_TYPE = 'list'
local BULLET_CHARACTER_PATTERN = '[-+*]'



local list_render = {}


local function count_list_depth(node)
   local depth = 0
   local ancestor = node:parent()
   while ancestor do
      if ancestor:type() == LIST_NODE_TYPE then depth = depth + 1 end
      ancestor = ancestor:parent()
   end
   return math.max(1, depth)
end

local function render_bullet(
   capture_dto,
   context_dto)

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
   })

end

function list_render.render(
   capture_dto,
   mod_context_dto)

   local context_dto = mod_context_dto
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
