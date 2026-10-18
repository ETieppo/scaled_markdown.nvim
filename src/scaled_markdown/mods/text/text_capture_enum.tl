local enum TextCaptureEnum
  'emphasis'
  'strong_emphasis'
  'strikethrough'
  'delimiter'
end

local record TextCaptureEnumProps
  type TextCaptureEnum = TextCaptureEnum

  EMPHASIS: TextCaptureEnum
  STRONG_EMPHASIS: TextCaptureEnum
  STRIKETHROUGH: TextCaptureEnum
  DELIMITER: TextCaptureEnum
end

local TEXT_CAPTURE_ENUM <const>: TextCaptureEnumProps = {
  EMPHASIS = 'emphasis',
  STRONG_EMPHASIS = 'strong_emphasis',
  STRIKETHROUGH = 'strikethrough',
  DELIMITER = 'delimiter',
}

return TEXT_CAPTURE_ENUM
