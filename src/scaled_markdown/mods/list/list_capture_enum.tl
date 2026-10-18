local enum ListCaptureEnum
  'bullet'
  'ordered'
end

local record ListCaptureEnumProps
  type ListCaptureEnum = ListCaptureEnum

  BULLET: ListCaptureEnum
  ORDERED: ListCaptureEnum
end

local LIST_CAPTURE_ENUM <const>: ListCaptureEnumProps = {
  BULLET = 'bullet',
  ORDERED = 'ordered',
}

return LIST_CAPTURE_ENUM
