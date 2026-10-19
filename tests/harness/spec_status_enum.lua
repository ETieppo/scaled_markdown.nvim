---@alias SpecStatusEnum 'failed'|'passed'|'skipped'

---@class SpecStatusEnumProps
---@field PASSED SpecStatusEnum
---@field FAILED SpecStatusEnum
---@field SKIPPED SpecStatusEnum

---@type SpecStatusEnumProps
local SPEC_STATUS_ENUM = {
  PASSED = 'passed',
  FAILED = 'failed',
  SKIPPED = 'skipped',
}

return SPEC_STATUS_ENUM
