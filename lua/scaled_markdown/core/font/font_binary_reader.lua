local BYTE_RANGE = 256
local UINT16_RANGE = 65536
local INT16_LIMIT = 32768
local INT8_LIMIT = 128
local UINT32_LIMIT = 4294967296
local INT32_LIMIT = 2147483648
local FIXED_DIVISOR = 65536
local F2DOT14_DIVISOR = 16384
local TAG_LENGTH = 4

---@class font_binary_reader
local font_binary_reader = {}

---@param data string
---@param offset integer
---@return integer
function font_binary_reader.read_uint8(data, offset)
  return data:byte(offset + 1) or 0
end

---@param data string
---@param offset integer
---@return integer
function font_binary_reader.read_int8(data, offset)
  local value = font_binary_reader.read_uint8(data, offset)
  return value >= INT8_LIMIT and value - BYTE_RANGE or value
end

---@param data string
---@param offset integer
---@return integer
function font_binary_reader.read_uint16(data, offset)
  local high_byte, low_byte = data:byte(offset + 1, offset + 2)
  return (high_byte or 0) * BYTE_RANGE + (low_byte or 0)
end

---@param data string
---@param offset integer
---@return integer
function font_binary_reader.read_int16(data, offset)
  local value = font_binary_reader.read_uint16(data, offset)
  return value >= INT16_LIMIT and value - UINT16_RANGE or value
end

---@param data string
---@param offset integer
---@return integer
function font_binary_reader.read_uint32(data, offset)
  return font_binary_reader.read_uint16(data, offset) * UINT16_RANGE
    + font_binary_reader.read_uint16(data, offset + 2)
end

---@param data string
---@param offset integer
---@return integer
function font_binary_reader.read_int32(data, offset)
  local value = font_binary_reader.read_uint32(data, offset)
  return value >= INT32_LIMIT and value - UINT32_LIMIT or value
end

---@param data string
---@param offset integer
---@param size integer
---@return integer
function font_binary_reader.read_uint_of_size(data, offset, size)
  local value = 0
  for byte_index = 0, size - 1 do
    value = value * BYTE_RANGE
      + font_binary_reader.read_uint8(data, offset + byte_index)
  end
  return value
end

---@param data string
---@param offset integer
---@return number
function font_binary_reader.read_fixed(data, offset)
  return font_binary_reader.read_int32(data, offset) / FIXED_DIVISOR
end

---@param data string
---@param offset integer
---@return number
function font_binary_reader.read_f2dot14(data, offset)
  return font_binary_reader.read_int16(data, offset) / F2DOT14_DIVISOR
end

---@param data string
---@param offset integer
---@return string
function font_binary_reader.read_tag(data, offset)
  return data:sub(offset + 1, offset + TAG_LENGTH)
end

---@param value integer
---@param flag integer
---@return boolean
function font_binary_reader.has_flag(value, flag)
  return math.floor(value / flag) % 2 == 1
end

return font_binary_reader
