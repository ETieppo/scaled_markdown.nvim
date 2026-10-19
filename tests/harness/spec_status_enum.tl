local enum SpecStatusEnum
    'passed'
    'failed'
    'skipped'
end

local record SpecStatusEnumProps
    type SpecStatusEnum = SpecStatusEnum

    PASSED: SpecStatusEnum
    FAILED: SpecStatusEnum
    SKIPPED: SpecStatusEnum
end

local SPEC_STATUS_ENUM <const>: SpecStatusEnumProps = {
    PASSED = "passed",
    FAILED = "failed",
    SKIPPED = "skipped",
}

return SPEC_STATUS_ENUM
