local font_binary_reader =
  require 'scaled_markdown.core.font.font_binary_reader'

local WEIGHT_CLASS_OFFSET = 4
local SELECTION_FLAGS_OFFSET = 62
local MAC_STYLE_OFFSET = 44
local ITALIC_SELECTION_FLAG = 1
local BOLD_SELECTION_FLAG = 32
local OBLIQUE_SELECTION_FLAG = 512
local BOLD_MAC_STYLE_FLAG = 1
local ITALIC_MAC_STYLE_FLAG = 2
local REGULAR_WEIGHT = 400
local BOLD_WEIGHT = 700

---@class FontStyleProps
---@field weight integer
---@field is_italic boolean

---@class font_style_reader
local font_style_reader = {}

---@param data string
---@return FontStyleProps
local function read_from_os2(data)
  local selection_flags =
    font_binary_reader.read_uint16(data, SELECTION_FLAGS_OFFSET)
  local weight = font_binary_reader.read_uint16(data, WEIGHT_CLASS_OFFSET)
  if weight == 0 then
    weight = font_binary_reader.has_flag(selection_flags, BOLD_SELECTION_FLAG)
        and BOLD_WEIGHT
      or REGULAR_WEIGHT
  end
  return {
    weight = weight,
    is_italic = font_binary_reader.has_flag(
      selection_flags,
      ITALIC_SELECTION_FLAG
    )
      or font_binary_reader.has_flag(selection_flags, OBLIQUE_SELECTION_FLAG),
  }
end

---@param data string
---@return FontStyleProps
local function read_from_head(data)
  local mac_style = font_binary_reader.read_uint16(data, MAC_STYLE_OFFSET)
  return {
    weight = font_binary_reader.has_flag(mac_style, BOLD_MAC_STYLE_FLAG)
        and BOLD_WEIGHT
      or REGULAR_WEIGHT,
    is_italic = font_binary_reader.has_flag(mac_style, ITALIC_MAC_STYLE_FLAG),
  }
end

---@param os2_data? string
---@param head_data? string
---@return FontStyleProps
function font_style_reader.read(os2_data, head_data)
  if os2_data and #os2_data > SELECTION_FLAGS_OFFSET then
    return read_from_os2(os2_data)
  end
  if head_data and #head_data > MAC_STYLE_OFFSET then
    return read_from_head(head_data)
  end
  return { weight = REGULAR_WEIGHT, is_italic = false }
end

return font_style_reader
