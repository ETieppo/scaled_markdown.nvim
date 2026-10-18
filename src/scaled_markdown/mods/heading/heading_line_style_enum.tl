local enum HeadingLineStyleEnum
  'pill'
  'accent'
  'muted'
end

local record HeadingLineStyleEnumProps
  type HeadingLineStyleEnum = HeadingLineStyleEnum

  PILL: HeadingLineStyleEnum
  ACCENT: HeadingLineStyleEnum
  MUTED: HeadingLineStyleEnum
end

local HEADING_LINE_STYLE_ENUM <const>: HeadingLineStyleEnumProps = {
  PILL = 'pill',
  ACCENT = 'accent',
  MUTED = 'muted',
}

return HEADING_LINE_STYLE_ENUM
