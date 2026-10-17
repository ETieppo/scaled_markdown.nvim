local type CellSizeProps = require 'scaled_markdown.core.types.cell_size_props'
local ffi = require 'ffi'
local config_store = require 'scaled_markdown.core.config.config_store'

local TIOCGWINSZ <const> = 0x5413
local TTY_DEVICE_PATH <const> = '/dev/tty'
local READ_WRITE_FLAG <const> = 2
local STANDARD_FILE_DESCRIPTORS <const>: {integer} = { 1, 0, 2 }
local WINSIZE_TYPE_NAME <const> = 'scaled_markdown_winsize'

local WINSIZE_DECLARATION <const> = [[
typedef struct {
  unsigned short row;
  unsigned short col;
  unsigned short xpixel;
  unsigned short ypixel;
} scaled_markdown_winsize;
]]
local C_FUNCTION_DECLARATIONS <const>: {string: string} = {
  ioctl = 'int ioctl(int fd, unsigned long request, ...);',
  open = 'int open(const char *path, int flags);',
  close = 'int close(int fd);',
}

local record WinsizeProps
  row: integer
  col: integer
  xpixel: integer
  ypixel: integer
end

local function is_declared(c_name: string): boolean
  return (pcall(function(): any return (ffi.C as {string: any})[c_name] end))
end

local function declare_bindings(): boolean
  if
    not pcall(ffi.typeof, WINSIZE_TYPE_NAME)
    and not pcall(ffi.cdef, WINSIZE_DECLARATION)
  then
    return false
  end
  for c_name, declaration in pairs(C_FUNCTION_DECLARATIONS) do
    if not is_declared(c_name) and not pcall(ffi.cdef, declaration) then
      return false
    end
  end
  return true
end

local are_bindings_ready = declare_bindings()

local record terminal_cell_size
end

local function read_window_size(file_descriptor: integer): CellSizeProps
  local window_size = ffi.new(WINSIZE_TYPE_NAME) as WinsizeProps
  if ffi.C.ioctl(file_descriptor, TIOCGWINSZ, window_size) ~= 0 then
    return nil
  end
  if
    window_size.xpixel == 0
    or window_size.ypixel == 0
    or window_size.col == 0
    or window_size.row == 0
  then
    return nil
  end
  return {
    width = math.floor(window_size.xpixel / window_size.col),
    height = math.floor(window_size.ypixel / window_size.row),
  }
end

local function read_from_tty_device(): CellSizeProps
  local file_descriptor = ffi.C.open(TTY_DEVICE_PATH, READ_WRITE_FLAG)
  if file_descriptor < 0 then return nil end
  local cell_size = read_window_size(file_descriptor)
  ffi.C.close(file_descriptor)
  return cell_size
end

local function read_from_terminal(): CellSizeProps
  if not are_bindings_ready then return nil end
  local cell_size = read_from_tty_device()
  for _, file_descriptor in ipairs(STANDARD_FILE_DESCRIPTORS) do
    cell_size = cell_size or read_window_size(file_descriptor)
  end
  return cell_size
end

function terminal_cell_size.measure(
): CellSizeProps return read_from_terminal() end

function terminal_cell_size.resolve(): CellSizeProps
  local terminal_config = config_store.get().terminal
  local measured_size: CellSizeProps = read_from_terminal() or {}
  return {
    width = terminal_config.cell_width_pixels
      or measured_size.width
      or terminal_config.fallback_cell_width_pixels,
    height = terminal_config.cell_height_pixels
      or measured_size.height
      or terminal_config.fallback_cell_height_pixels,
  }
end

return terminal_cell_size
