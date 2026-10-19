local font_directories = require 'scaled_markdown.core.font.font_directories'
local font_name_reader = require 'scaled_markdown.core.font.font_name_reader'
local font_style_reader = require 'scaled_markdown.core.font.font_style_reader'
local sfnt_table_directory =
  require 'scaled_markdown.core.font.sfnt_table_directory'

---@type string[]
local FONT_FILE_PATTERNS = { '%.ttf$', '%.otf$', '%.ttc$', '%.otc$' }
local READ_BINARY_MODE = 'rb'
local SEEK_FROM_START = 'set'
local NAME_TABLE_TAG = 'name'
local STYLE_TABLE_TAG = 'OS/2'
local HEADER_TABLE_TAG = 'head'

---@class font_catalog
local font_catalog = {}

---@type string[]?
local font_files = nil
---@type table<string, FontCatalogEntryProps[]>
local entries_by_path = {}

---@param name string
---@return boolean
local function is_font_file(name)
  local lower_name = name:lower()
  for _, pattern in ipairs(FONT_FILE_PATTERNS) do
    if lower_name:find(pattern) then return true end
  end
  return false
end

---@param file file*
---@param font_table FontTableProps
---@return string?
local function read_table(file, font_table)
  if not font_table then return nil end
  file:seek(SEEK_FROM_START, font_table.offset)
  return file:read(font_table.length)
end

---@param file file*
---@param path string
---@param face_index integer
---@return FontCatalogEntryProps?
local function read_face_entry(file, path, face_index)
  local tables = sfnt_table_directory.read(
    ---@param offset integer
    ---@param length integer
    ---@return string
    function(offset, length)
      file:seek(SEEK_FROM_START, offset)
      return file:read(length) or ''
    end,
    face_index
  )
  if not tables or not tables[NAME_TABLE_TAG] then return nil end
  local name_data = read_table(file, tables[NAME_TABLE_TAG])
  if not name_data then return nil end
  local names = font_name_reader.read(name_data, 0)
  local style = font_style_reader.read(
    read_table(file, tables[STYLE_TABLE_TAG]),
    read_table(file, tables[HEADER_TABLE_TAG])
  )
  return {
    path = path,
    face_index = face_index,
    family_names = names.family_names,
    style_name = names.style_name,
    weight = style.weight,
    is_italic = style.is_italic,
  }
end

---@param path string
---@return FontCatalogEntryProps[]
local function read_file_entries(path)
  local file = io.open(path, READ_BINARY_MODE)
  if not file then return {} end
  ---@type FontCatalogEntryProps[]
  local entries = {}
  local ok = pcall(function()
    local face_count = sfnt_table_directory.count_faces(
      ---@param offset integer
      ---@param length integer
      ---@return string
      function(offset, length)
        file:seek(SEEK_FROM_START, offset)
        return file:read(length) or ''
      end
    )
    for face_index = 0, face_count - 1 do
      local entry = read_face_entry(file, path, face_index)
      if entry then entries[#entries + 1] = entry end
    end
  end)
  file:close()
  return ok and entries or {}
end

---@return string[]
function font_catalog.list_files()
  if not font_files then
    font_files = {}
    for _, directory in ipairs(font_directories.list()) do
      local directory_files = vim.fs.find(
        is_font_file,
        { path = directory, limit = math.huge, follow = true }
      )
      vim.list_extend(font_files, directory_files)
    end
  end
  return font_files
end

---@param path string
---@return FontCatalogEntryProps[]
function font_catalog.read_entries(path)
  if not entries_by_path[path] then
    entries_by_path[path] = read_file_entries(path)
  end
  return entries_by_path[path]
end

return font_catalog
