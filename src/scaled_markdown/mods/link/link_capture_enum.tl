local enum LinkCaptureEnum
  'labeled_link'
  'autolink'
end

local record LinkCaptureEnumProps
  type LinkCaptureEnum = LinkCaptureEnum

  LABELED_LINK: LinkCaptureEnum
  AUTOLINK: LinkCaptureEnum
end

local LINK_CAPTURE_ENUM <const>: LinkCaptureEnumProps = {
  LABELED_LINK = 'labeled_link',
  AUTOLINK = 'autolink',
}

return LINK_CAPTURE_ENUM
