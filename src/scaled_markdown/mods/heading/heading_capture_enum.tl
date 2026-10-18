local enum HeadingCaptureEnum
  'atx_heading'
  'setext_heading'
end

local record HeadingCaptureEnumProps
  type HeadingCaptureEnum = HeadingCaptureEnum

  ATX_HEADING: HeadingCaptureEnum
  SETEXT_HEADING: HeadingCaptureEnum
end

local HEADING_CAPTURE_ENUM <const>: HeadingCaptureEnumProps = {
  ATX_HEADING = 'atx_heading',
  SETEXT_HEADING = 'setext_heading',
}

return HEADING_CAPTURE_ENUM
