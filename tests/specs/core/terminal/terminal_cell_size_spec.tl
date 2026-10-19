local expect = require("harness.assertions")
local spec = require("harness.spec")
local plugin_session = require("helpers.plugin_session")
local terminal_cell_size = require("scaled_markdown.core.terminal.terminal_cell_size")

local CONFIGURED_WIDTH <const> = 9
local CONFIGURED_HEIGHT <const> = 19
local FALLBACK_WIDTH <const> = 11
local FALLBACK_HEIGHT <const> = 23

local function is_finite_positive(value: number): boolean
    return value ~= nil and value > 0 and value < math.huge
end

spec.describe(
    "terminal_cell_size",
    function()
        spec.it(
            "prefers explicitly configured cell sizes",
            function()
                plugin_session.start(
                    {
                        renderer = "plain",
                        terminal = {
                            cell_width_pixels = CONFIGURED_WIDTH,
                            cell_height_pixels = CONFIGURED_HEIGHT,
                        },
                    }
                )
                expect.deep_equal(
                    terminal_cell_size.resolve(),
                    {width = CONFIGURED_WIDTH, height = CONFIGURED_HEIGHT},
                    "configured size"
                )
            end
        )

        spec.it(
            "falls back when the terminal cannot be measured",
            function()
                plugin_session.start(
                    {
                        renderer = "plain",
                        terminal = {
                            fallback_cell_width_pixels = FALLBACK_WIDTH,
                            fallback_cell_height_pixels = FALLBACK_HEIGHT,
                        },
                    }
                )
                local measured = terminal_cell_size.measure()
                local resolved = terminal_cell_size.resolve()
                if measured then
                    expect.deep_equal(resolved, measured, "measured size used")
                else
                    expect.deep_equal(
                        resolved,
                        {width = FALLBACK_WIDTH, height = FALLBACK_HEIGHT},
                        "fallback size"
                    )
                end
            end
        )

        spec.it(
            "always resolves finite positive sizes",
            function()
                plugin_session.start()
                local resolved = terminal_cell_size.resolve()
                expect.truthy(is_finite_positive(resolved.width), "finite width")
                expect.truthy(is_finite_positive(resolved.height), "finite height")
            end
        )
    end
)
