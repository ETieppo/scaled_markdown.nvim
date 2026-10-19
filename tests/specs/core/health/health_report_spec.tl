local expect = require("harness.assertions")
local spec = require("harness.spec")
local plugin_session = require("helpers.plugin_session")

local HEALTH_COMMAND <const> = "checkhealth scaled_markdown"
local HEALTH_WAIT_MS <const> = 5000
local REPORT_END_MARKER <const> = "cell size"
local LINE_SEPARATOR <const> = "\n"
local REPORTED_RENDERERS <const>: {string} = {
    "graphics", "typeface", "toilet", "figlet"
}

local function read_current_buffer(): string
    return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), LINE_SEPARATOR)
end

local function run_health(): string
    vim.cmd(HEALTH_COMMAND)
    vim.wait(
        HEALTH_WAIT_MS,
        function(): boolean
            return read_current_buffer():find(REPORT_END_MARKER) ~= nil
        end
    )
    return read_current_buffer()
end

spec.describe(
    "health_report",
    function()
        spec.it(
            "reports parsers, renderers and terminal support",
            function()
                plugin_session.start()
                local report = run_health()
                expect.matches(report, "treesitter parser 'markdown' found", "markdown")
                expect.matches(
                    report, "treesitter parser 'markdown_inline' found", "inline parser"
                )
                expect.matches(
                    report, "configured renderer: plain", "configured renderer"
                )
                for _, renderer in ipairs(REPORTED_RENDERERS) do
                    expect.matches(report, ("renderer '%s'"):format(renderer), renderer)
                end
                expect.matches(report, REPORT_END_MARKER, "cell size line")
            end
        )
    end
)
