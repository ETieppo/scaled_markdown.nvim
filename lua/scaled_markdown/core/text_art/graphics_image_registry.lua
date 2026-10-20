local kitty_graphics_protocol =
  require 'scaled_markdown.core.terminal.kitty_graphics_protocol'

local IMAGE_HIGHLIGHT_PREFIX = 'ScaledMarkdownImage'
local IMAGE_ID_COLOR_FORMAT = '#%06x'
local IMAGE_ID_PROCESS_SPREAD = 0x3FF
local IMAGE_ID_BLOCK_SIZE = 0x4000

---@class graphics_image_registry
local graphics_image_registry = {}

local next_image_id = (vim.fn.getpid() % IMAGE_ID_PROCESS_SPREAD)
    * IMAGE_ID_BLOCK_SIZE
  + 1
---@type integer[]
local transmitted_image_ids = {}
---@type table<integer, PositionedImageProps>
local positioned_images_by_id = {}

---@return integer
local function next_id()
  local image_id = next_image_id
  next_image_id = next_image_id + 1
  return image_id
end

---@return integer
---@return string
function graphics_image_registry.allocate()
  local image_id = next_id()
  local highlight_group = IMAGE_HIGHLIGHT_PREFIX .. image_id
  vim.api.nvim_set_hl(
    0,
    highlight_group,
    { fg = IMAGE_ID_COLOR_FORMAT:format(image_id) }
  )
  transmitted_image_ids[#transmitted_image_ids + 1] = image_id
  return image_id, highlight_group
end

---@param payload string
---@param columns integer
---@param rows integer
---@return integer
function graphics_image_registry.register_positioned(payload, columns, rows)
  local image_id = next_id()
  positioned_images_by_id[image_id] =
    { payload = payload, columns = columns, rows = rows }
  return image_id
end

---@param image_id integer
---@return PositionedImageProps?
function graphics_image_registry.positioned(image_id)
  return positioned_images_by_id[image_id]
end

function graphics_image_registry.release_all()
  for _, image_id in ipairs(transmitted_image_ids) do
    pcall(kitty_graphics_protocol.delete_image, image_id)
  end
  transmitted_image_ids = {}
  positioned_images_by_id = {}
end

return graphics_image_registry
