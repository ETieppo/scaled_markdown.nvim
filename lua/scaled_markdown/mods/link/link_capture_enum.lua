---@alias LinkCaptureEnum 'autolink'|'labeled_link'

---@class LinkCaptureEnumProps
---@field LABELED_LINK LinkCaptureEnum
---@field AUTOLINK LinkCaptureEnum

---@type LinkCaptureEnumProps
local LINK_CAPTURE_ENUM = {
  LABELED_LINK = 'labeled_link',
  AUTOLINK = 'autolink',
}

return LINK_CAPTURE_ENUM
