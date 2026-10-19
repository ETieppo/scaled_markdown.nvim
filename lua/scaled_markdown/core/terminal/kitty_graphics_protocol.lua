local ESCAPE_START = '\27_G'
local ESCAPE_END = '\27\\'
local TRANSMIT_FILE_FORMAT = 'a=T,U=1,f=32,s=%d,v=%d,t=t,q=2,i=%d,c=%d,r=%d;%s'
local DELETE_IMAGE_FORMAT = 'a=d,d=I,q=2,i=%d'

---@class kitty_graphics_protocol
local kitty_graphics_protocol = {}

---@param control_payload string
local function send(control_payload)
  vim.api.nvim_ui_send(ESCAPE_START .. control_payload .. ESCAPE_END)
end

---@param image_id integer
---@param file_path string
---@param pixel_width integer
---@param pixel_height integer
---@param columns integer
---@param rows integer
function kitty_graphics_protocol.transmit_temporary_file(
  image_id,
  file_path,
  pixel_width,
  pixel_height,
  columns,
  rows
)
  send(
    TRANSMIT_FILE_FORMAT:format(
      pixel_width,
      pixel_height,
      image_id,
      columns,
      rows,
      vim.base64.encode(file_path)
    )
  )
end

---@param image_id integer
function kitty_graphics_protocol.delete_image(image_id)
  send(DELETE_IMAGE_FORMAT:format(image_id))
end

return kitty_graphics_protocol
