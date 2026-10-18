local enum InlineCodeCaptureEnum
  'code_span'
  'delimiter'
end

local record InlineCodeCaptureEnumProps
  type InlineCodeCaptureEnum = InlineCodeCaptureEnum

  CODE_SPAN: InlineCodeCaptureEnum
  DELIMITER: InlineCodeCaptureEnum
end

local INLINE_CODE_CAPTURE_ENUM <const>: InlineCodeCaptureEnumProps = {
  CODE_SPAN = 'code_span',
  DELIMITER = 'delimiter',
}

return INLINE_CODE_CAPTURE_ENUM
