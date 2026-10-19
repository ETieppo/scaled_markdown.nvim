local enum CheckboxCaptureEnum
  'unchecked'
  'checked'
end

local record CheckboxCaptureEnumProps
  type CheckboxCaptureEnum = CheckboxCaptureEnum

  UNCHECKED: CheckboxCaptureEnum
  CHECKED: CheckboxCaptureEnum
end

local CHECKBOX_CAPTURE_ENUM <const>: CheckboxCaptureEnumProps = {
  UNCHECKED = 'unchecked',
  CHECKED = 'checked',
}

return CHECKBOX_CAPTURE_ENUM
