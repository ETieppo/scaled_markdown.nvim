local font_binary_reader =
  require 'scaled_markdown.core.font.font_binary_reader'

local COLLECTION_TAG = 'ttcf'
local COLLECTION_HEADER_LENGTH = 12
local COLLECTION_FACE_COUNT_OFFSET = 8
local OFFSET_TABLE_LENGTH = 12
local TABLE_COUNT_OFFSET = 4
local TABLE_RECORD_LENGTH = 16
local TABLE_RECORD_OFFSET_FIELD = 8
local TABLE_RECORD_LENGTH_FIELD = 12
---@type table<string, boolean>
local SUPPORTED_SFNT_VERSIONS = {
  ['\0\1\0\0'] = true,
  ['OTTO'] = true,
  ['true'] = true,
}

---@class sfnt_table_directory
local sfnt_table_directory = {}

---@param read_bytes FontByteSourceProps
---@param face_index integer
---@return integer?
local function resolve_face_offset(read_bytes, face_index)
  local header = read_bytes(0, COLLECTION_HEADER_LENGTH)
  if font_binary_reader.read_tag(header, 0) ~= COLLECTION_TAG then
    return face_index == 0 and 0 or nil
  end
  local face_count =
    font_binary_reader.read_uint32(header, COLLECTION_FACE_COUNT_OFFSET)
  if face_index >= face_count then return nil end
  return font_binary_reader.read_uint32(
    read_bytes(COLLECTION_HEADER_LENGTH + 4 * face_index, 4),
    0
  )
end

---@param read_bytes FontByteSourceProps
---@return integer
function sfnt_table_directory.count_faces(read_bytes)
  local header = read_bytes(0, COLLECTION_HEADER_LENGTH)
  if font_binary_reader.read_tag(header, 0) ~= COLLECTION_TAG then return 1 end
  return font_binary_reader.read_uint32(header, COLLECTION_FACE_COUNT_OFFSET)
end

---@param read_bytes FontByteSourceProps
---@param face_index integer
---@return table<string, FontTableProps>?
function sfnt_table_directory.read(read_bytes, face_index)
  local face_offset = resolve_face_offset(read_bytes, face_index)
  if not face_offset then return nil end
  local offset_table = read_bytes(face_offset, OFFSET_TABLE_LENGTH)
  if
    not SUPPORTED_SFNT_VERSIONS[font_binary_reader.read_tag(offset_table, 0)]
  then
    return nil
  end
  local table_count =
    font_binary_reader.read_uint16(offset_table, TABLE_COUNT_OFFSET)
  local records = read_bytes(
    face_offset + OFFSET_TABLE_LENGTH,
    table_count * TABLE_RECORD_LENGTH
  )
  ---@type table<string, FontTableProps>
  local tables = {}
  for table_index = 0, table_count - 1 do
    local record_offset = table_index * TABLE_RECORD_LENGTH
    tables[font_binary_reader.read_tag(records, record_offset)] = {
      offset = font_binary_reader.read_uint32(
        records,
        record_offset + TABLE_RECORD_OFFSET_FIELD
      ),
      length = font_binary_reader.read_uint32(
        records,
        record_offset + TABLE_RECORD_LENGTH_FIELD
      ),
    }
  end
  return tables
end

return sfnt_table_directory
