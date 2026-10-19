local enum AlignmentEnum
  'left'
  'center'
  'right'
end

local record AlignmentEnumProps
  type AlignmentEnum = AlignmentEnum

  LEFT: AlignmentEnum
  CENTER: AlignmentEnum
  RIGHT: AlignmentEnum
end

local ALIGNMENT_ENUM <const>: AlignmentEnumProps = {
  LEFT = 'left',
  CENTER = 'center',
  RIGHT = 'right',
}

return ALIGNMENT_ENUM
