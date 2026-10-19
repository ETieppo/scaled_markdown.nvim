local PATH_LIST_SEPARATOR_PATTERN = '[^:;]+'
local DEFAULT_DATA_DIRECTORIES = '/usr/local/share:/usr/share'
local FONTS_SUBDIRECTORY = '/fonts'

---@class font_directories
local font_directories = {}

---@param directories string[]
---@param seen_directories table<string, boolean>
---@param directory string
local function append_existing(directories, seen_directories, directory)
  if not directory or seen_directories[directory] then return end
  seen_directories[directory] = true
  if vim.uv.fs_stat(directory) then
    directories[#directories + 1] = directory
  end
end

---@return string[]
local function build_candidates()
  local home = vim.env.HOME or vim.env.USERPROFILE
  local data_home = vim.env.XDG_DATA_HOME or (home and home .. '/.local/share')
  ---@type string[]
  local candidates = {}
  if data_home then
    candidates[#candidates + 1] = data_home .. FONTS_SUBDIRECTORY
  end
  if home then
    candidates[#candidates + 1] = home .. '/.fonts'
    candidates[#candidates + 1] = home .. '/Library/Fonts'
  end
  for data_directory in
    (vim.env.XDG_DATA_DIRS or DEFAULT_DATA_DIRECTORIES):gmatch(
      PATH_LIST_SEPARATOR_PATTERN
    )
  do
    candidates[#candidates + 1] = data_directory .. FONTS_SUBDIRECTORY
  end
  candidates[#candidates + 1] = '/Library/Fonts'
  candidates[#candidates + 1] = '/System/Library/Fonts'
  if vim.env.LOCALAPPDATA then
    candidates[#candidates + 1] = vim.env.LOCALAPPDATA
      .. '/Microsoft/Windows/Fonts'
  end
  if vim.env.WINDIR then
    candidates[#candidates + 1] = vim.env.WINDIR .. '/Fonts'
  end
  return candidates
end

---@return string[]
function font_directories.list()
  ---@type string[]
  local directories = {}
  ---@type table<string, boolean>
  local seen_directories = {}
  for _, candidate in ipairs(build_candidates()) do
    append_existing(directories, seen_directories, candidate)
  end
  return directories
end

return font_directories
