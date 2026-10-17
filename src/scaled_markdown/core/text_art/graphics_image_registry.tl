local kitty_graphics_protocol =
  require 'scaled_markdown.core.terminal.kitty_graphics_protocol'

local IMAGE_HIGHLIGHT_PREFIX <const> = 'ScaledMarkdownImage'
local IMAGE_ID_COLOR_FORMAT <const> = '#%06x'
local IMAGE_ID_PROCESS_SPREAD <const> = 0x3FF
local IMAGE_ID_BLOCK_SIZE <const> = 0x4000

local record graphics_image_registry
end

local next_image_id = (vim.fn.getpid() % IMAGE_ID_PROCESS_SPREAD)
    * IMAGE_ID_BLOCK_SIZE
  + 1
local registered_image_ids: {integer} = {}

function graphics_image_registry.allocate(): integer, string
  local image_id = next_image_id
  next_image_id = next_image_id + 1
  local highlight_group = IMAGE_HIGHLIGHT_PREFIX .. image_id
  vim.api.nvim_set_hl(
    0,
    highlight_group,
    { fg = IMAGE_ID_COLOR_FORMAT:format(image_id) }
  )
  registered_image_ids[#registered_image_ids + 1] = image_id
  return image_id, highlight_group
end

function graphics_image_registry.release_all()
  for _, image_id in ipairs(registered_image_ids) do
    pcall(kitty_graphics_protocol.delete_image, image_id)
  end
  registered_image_ids = {}
end

return graphics_image_registry
