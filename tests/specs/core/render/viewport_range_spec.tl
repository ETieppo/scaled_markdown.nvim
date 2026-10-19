local expect = require("harness.assertions")
local spec = require("harness.spec")
local buffer_factory = require("helpers.buffer_factory")
local CORE_CONSTANTS = require("scaled_markdown.core.constants")
local viewport_range = require("scaled_markdown.core.render.viewport_range")

local LONG_LINE_COUNT <const> = 1000
local SHORT_LINE_COUNT <const> = 5
local LINE_FORMAT <const> = "line %d"
local CENTER_CURSOR <const> = "normal! zz"

local function build_lines(count: integer): {string}
    local lines: {string} = {}
    for index = 1, count do
        lines[index] = LINE_FORMAT:format(index)
    end
    return lines
end

spec.describe(
    "viewport_range",
    function()
        spec.it(
            "covers the whole buffer when it fits in the margin",
            function()
                local buf = buffer_factory.from_lines(build_lines(SHORT_LINE_COUNT))
                local start_row, end_row = viewport_range.resolve(
                    vim.api.nvim_get_current_win(), buf
                )
                expect.equal(start_row, 0, "start row")
                expect.equal(end_row, SHORT_LINE_COUNT, "end row")
            end
        )

        spec.it(
            "extends the visible lines by the margin on both sides",
            function()
                local buf = buffer_factory.from_lines(build_lines(LONG_LINE_COUNT))
                local win = vim.api.nvim_get_current_win()
                vim.api.nvim_win_set_cursor(win, {math.floor(LONG_LINE_COUNT / 2), 0})
                vim.cmd(CENTER_CURSOR)
                local top_row = vim.fn.line("w0") - 1
                local bottom_row = vim.fn.line("w$")
                local start_row, end_row = viewport_range.resolve(win, buf)
                expect.equal(
                    start_row, top_row - CORE_CONSTANTS.VIEWPORT_MARGIN_LINES, "start"
                )
                expect.equal(
                    end_row, bottom_row + CORE_CONSTANTS.VIEWPORT_MARGIN_LINES, "end"
                )
            end
        )

        spec.it(
            "clamps the range to the buffer edges",
            function()
                local buf = buffer_factory.from_lines(build_lines(LONG_LINE_COUNT))
                local win = vim.api.nvim_get_current_win()
                vim.api.nvim_win_set_cursor(win, {LONG_LINE_COUNT, 0})
                local _, end_row = viewport_range.resolve(win, buf)
                expect.equal(end_row, LONG_LINE_COUNT, "end clamped")
            end
        )
    end
)
