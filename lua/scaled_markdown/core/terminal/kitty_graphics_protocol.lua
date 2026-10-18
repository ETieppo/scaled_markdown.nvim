local ESCAPE_START = '\27_G'
local ESCAPE_END = '\27\\'
local TRANSMIT_FILE_FORMAT = 'a=T,U=1,f=100,t=t,q=2,i=%d,c=%d,r=%d;%s'
local DELETE_IMAGE_FORMAT = 'a=d,d=I,q=2,i=%d'

local kitty_graphics_protocol = {}


local function send(control_payload)
   vim.api.nvim_ui_send(ESCAPE_START .. control_payload .. ESCAPE_END)
end

function kitty_graphics_protocol.transmit_temporary_file(
   image_id,
   file_path,
   columns,
   rows)

   send(
   TRANSMIT_FILE_FORMAT:format(
   image_id,
   columns,
   rows,
   vim.base64.encode(file_path)))


end

function kitty_graphics_protocol.delete_image(image_id)
   send(DELETE_IMAGE_FORMAT:format(image_id))
end

return kitty_graphics_protocol
