local enum CalloutTypeEnum
  'NOTE'
  'TIP'
  'IMPORTANT'
  'WARNING'
  'CAUTION'
end

local record CalloutTypeEnumProps
  type CalloutTypeEnum = CalloutTypeEnum

  NOTE: CalloutTypeEnum
  TIP: CalloutTypeEnum
  IMPORTANT: CalloutTypeEnum
  WARNING: CalloutTypeEnum
  CAUTION: CalloutTypeEnum
end

local CALLOUT_TYPE_ENUM <const>: CalloutTypeEnumProps = {
  NOTE = 'NOTE',
  TIP = 'TIP',
  IMPORTANT = 'IMPORTANT',
  WARNING = 'WARNING',
  CAUTION = 'CAUTION',
}

return CALLOUT_TYPE_ENUM
