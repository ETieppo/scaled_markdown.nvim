---@alias TextCaptureEnum 'delimiter'|'emphasis'|'strikethrough'|'strong_emphasis'

---@class TextCaptureEnumProps
---@field EMPHASIS TextCaptureEnum
---@field STRONG_EMPHASIS TextCaptureEnum
---@field STRIKETHROUGH TextCaptureEnum
---@field DELIMITER TextCaptureEnum

---@type TextCaptureEnumProps
local TEXT_CAPTURE_ENUM = {
  EMPHASIS = 'emphasis',
  STRONG_EMPHASIS = 'strong_emphasis',
  STRIKETHROUGH = 'strikethrough',
  DELIMITER = 'delimiter',
}

return TEXT_CAPTURE_ENUM
