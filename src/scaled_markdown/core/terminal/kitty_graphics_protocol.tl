local ESCAPE_START <const> = '\27_G'
local ESCAPE_END <const> = '\27\\'
local TRANSMIT_FILE_FORMAT <const> = 'a=T,U=1,f=100,t=t,q=2,i=%d,c=%d,r=%d;%s'
local DELETE_IMAGE_FORMAT <const> = 'a=d,d=I,q=2,i=%d'

local record kitty_graphics_protocol
end

local function send(control_payload: string)
  vim.api.nvim_ui_send(ESCAPE_START .. control_payload .. ESCAPE_END)
end

function kitty_graphics_protocol.transmit_temporary_file(
  image_id: integer,
  file_path: string,
  columns: integer,
  rows: integer
)
  send(
    TRANSMIT_FILE_FORMAT:format(
      image_id,
      columns,
      rows,
      vim.base64.encode(file_path)
    )
  )
end

function kitty_graphics_protocol.delete_image(image_id: integer)
  send(DELETE_IMAGE_FORMAT:format(image_id))
end

return kitty_graphics_protocol
