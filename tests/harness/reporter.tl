local type SpecResultProps = require("harness.types.spec_result_props")
local SPEC_STATUS_ENUM = require("harness.spec_status_enum")
local type SpecStatusEnum = SPEC_STATUS_ENUM.SpecStatusEnum

local STATUS_SYMBOLS <const>: {SpecStatusEnum: string} = {
    [SPEC_STATUS_ENUM.PASSED] = "✓",
    [SPEC_STATUS_ENUM.FAILED] = "✗",
    [SPEC_STATUS_ENUM.SKIPPED] = "○",
}
local SUMMARY_FORMAT <const> = "%d passed, %d failed, %d skipped (%d specs, %.1fs)"
local TEST_LINE_FORMAT <const> = "  %s %s"
local DETAIL_LINE_FORMAT <const> = "      %s"
local SLOW_TEST_THRESHOLD_MS <const> = 1000
local SLOW_SUFFIX_FORMAT <const> = " (%.0f ms)"
local BUILD_FAILURE_HEADER <const> = "Teal build failed:"
local NO_SPECS_FORMAT <const> = "no spec files matched: %s"
local FILTER_SEPARATOR <const> = ", "

local record reporter
end

local function write_line(text: string)
    io.stdout:write(text, "\n")
end

function reporter.spec_file(display_path: string, results: {SpecResultProps})
    write_line(display_path)
    for _, result in ipairs(results) do
        local line = TEST_LINE_FORMAT:format(STATUS_SYMBOLS[result.status], result.name)
        if (result.duration_ms or 0) >= SLOW_TEST_THRESHOLD_MS then
            line = line .. SLOW_SUFFIX_FORMAT:format(result.duration_ms)
        end
        write_line(line)
        if result.message and result.status ~= SPEC_STATUS_ENUM.PASSED then
            write_line(DETAIL_LINE_FORMAT:format(result.message))
        end
    end
end

function reporter.build_failure(output: string)
    write_line(BUILD_FAILURE_HEADER)
    write_line(output)
end

function reporter.no_specs(filters: {string})
    write_line(NO_SPECS_FORMAT:format(table.concat(filters, FILTER_SEPARATOR)))
end

function reporter.summary(
    totals: {SpecStatusEnum: integer}, spec_count: integer, elapsed_seconds: number
)
    write_line("")
    write_line(
        SUMMARY_FORMAT:format(
            totals[SPEC_STATUS_ENUM.PASSED],
            totals[SPEC_STATUS_ENUM.FAILED],
            totals[SPEC_STATUS_ENUM.SKIPPED],
            spec_count,
            elapsed_seconds
        )
    )
end

return reporter
