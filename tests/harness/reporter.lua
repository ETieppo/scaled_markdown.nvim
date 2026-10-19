local SPEC_STATUS_ENUM = require 'harness.spec_status_enum'

---@type table<SpecStatusEnum, string>
local STATUS_SYMBOLS = {
  [SPEC_STATUS_ENUM.PASSED] = '✓',
  [SPEC_STATUS_ENUM.FAILED] = '✗',
  [SPEC_STATUS_ENUM.SKIPPED] = '○',
}
local SUMMARY_FORMAT = '%d passed, %d failed, %d skipped (%d specs, %.1fs)'
local TEST_LINE_FORMAT = '  %s %s'
local DETAIL_LINE_FORMAT = '      %s'
local SLOW_TEST_THRESHOLD_MS = 1000
local SLOW_SUFFIX_FORMAT = ' (%.0f ms)'
local NO_SPECS_FORMAT = 'no spec files matched: %s'
local FILTER_SEPARATOR = ', '

---@class reporter
local reporter = {}

---@param text string
local function write_line(text) io.stdout:write(text, '\n') end

---@param display_path string
---@param results SpecResultProps[]
function reporter.spec_file(display_path, results)
  write_line(display_path)
  for _, result in ipairs(results) do
    local line =
      TEST_LINE_FORMAT:format(STATUS_SYMBOLS[result.status], result.name)
    if (result.duration_ms or 0) >= SLOW_TEST_THRESHOLD_MS then
      line = line .. SLOW_SUFFIX_FORMAT:format(result.duration_ms)
    end
    write_line(line)
    if result.message and result.status ~= SPEC_STATUS_ENUM.PASSED then
      write_line(DETAIL_LINE_FORMAT:format(result.message))
    end
  end
end

---@param filters string[]
function reporter.no_specs(filters)
  write_line(NO_SPECS_FORMAT:format(table.concat(filters, FILTER_SEPARATOR)))
end

---@param totals table<SpecStatusEnum, integer>
---@param spec_count integer
---@param elapsed_seconds number
function reporter.summary(totals, spec_count, elapsed_seconds)
  write_line ''
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
