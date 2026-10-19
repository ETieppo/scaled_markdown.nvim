local tmux_client = require 'scaled_markdown.core.terminal.tmux_client'
local tmux_passthrough =
  require 'scaled_markdown.core.terminal.tmux_passthrough'

local ESCAPE_START = '\27_G'
local ESCAPE_END = '\27\\'
local CHUNK_SIZE = 4096
local MORE_CHUNKS_FLAG = 1
local LAST_CHUNK_FLAG = 0
local FIRST_CHUNK_FORMAT =
  'a=T,U=1,f=32,s=%d,v=%d,t=d,q=2,i=%d,c=%d,r=%d,m=%d;%s'
local NEXT_CHUNK_FORMAT = 'q=2,m=%d;%s'
local DELETE_IMAGE_FORMAT = 'a=d,d=I,q=2,i=%d'

---@class kitty_graphics_protocol
local kitty_graphics_protocol = {}

---@param control_payloads string[]
local function send(control_payloads)
  local is_inside_tmux = tmux_client.is_inside()
  ---@type string[]
  local sequences = {}
  for index, control_payload in ipairs(control_payloads) do
    local sequence = ESCAPE_START .. control_payload .. ESCAPE_END
    sequences[index] = is_inside_tmux and tmux_passthrough.wrap(sequence)
      or sequence
  end
  vim.api.nvim_ui_send(table.concat(sequences))
end

---@param encoded_pixels string
---@return string[]
local function split_chunks(encoded_pixels)
  ---@type string[]
  local chunks = {}
  for chunk_start = 1, math.max(1, #encoded_pixels), CHUNK_SIZE do
    chunks[#chunks + 1] =
      encoded_pixels:sub(chunk_start, chunk_start + CHUNK_SIZE - 1)
  end
  return chunks
end

---@param image_id integer
---@param rgba_pixels string
---@param pixel_width integer
---@param pixel_height integer
---@param columns integer
---@param rows integer
---@return string[]
function kitty_graphics_protocol.build_transmit_payloads(
  image_id,
  rgba_pixels,
  pixel_width,
  pixel_height,
  columns,
  rows
)
  local chunks = split_chunks(vim.base64.encode(rgba_pixels))
  ---@type string[]
  local control_payloads = {}
  for index, chunk in ipairs(chunks) do
    local chunk_flag = index < #chunks and MORE_CHUNKS_FLAG or LAST_CHUNK_FLAG
    control_payloads[index] = index == 1
        and FIRST_CHUNK_FORMAT:format(
          pixel_width,
          pixel_height,
          image_id,
          columns,
          rows,
          chunk_flag,
          chunk
        )
      or NEXT_CHUNK_FORMAT:format(chunk_flag, chunk)
  end
  return control_payloads
end

---@param image_id integer
---@param rgba_pixels string
---@param pixel_width integer
---@param pixel_height integer
---@param columns integer
---@param rows integer
function kitty_graphics_protocol.transmit_pixels(
  image_id,
  rgba_pixels,
  pixel_width,
  pixel_height,
  columns,
  rows
)
  send(
    kitty_graphics_protocol.build_transmit_payloads(
      image_id,
      rgba_pixels,
      pixel_width,
      pixel_height,
      columns,
      rows
    )
  )
end

---@param image_id integer
function kitty_graphics_protocol.delete_image(image_id)
  send { DELETE_IMAGE_FORMAT:format(image_id) }
end

return kitty_graphics_protocol
