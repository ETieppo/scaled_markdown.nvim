local SPEC_STATUS_ENUM = require("harness.spec_status_enum")
local type SpecStatusEnum = SPEC_STATUS_ENUM.SpecStatusEnum

local record SpecResultProps
    name: string
    status: SpecStatusEnum
    message: string
    duration_ms: number
end

return SpecResultProps
