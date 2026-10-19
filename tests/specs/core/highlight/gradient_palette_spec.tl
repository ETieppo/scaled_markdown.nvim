local expect = require("harness.assertions")
local spec = require("harness.spec")
local plugin_session = require("helpers.plugin_session")
local gradient_palette = require("scaled_markdown.core.highlight.gradient_palette")

local GRADIENT_PREFIX <const> = "ScaledMarkdownGradient"
local FILL_PREFIX <const> = "ScaledMarkdownGradientFill"
local HEX_COLOR_FORMAT <const> = "#%06x"
local CONFIGURED_STEPS <const> = 5
local START_COLOR <const> = "#102030"
local END_COLOR <const> = "#a0b0c0"
local SINGLE_COLOR <const> = "#ff0000"
local FILL_FOREGROUND <const> = "#010203"

local function foreground_of(group_name: string): string
    local highlight = vim.api.nvim_get_hl(0, {name = group_name, link = false})
    return highlight.fg and HEX_COLOR_FORMAT:format(highlight.fg) or nil
end

local function background_of(group_name: string): string
    local highlight = vim.api.nvim_get_hl(0, {name = group_name, link = false})
    return highlight.bg and HEX_COLOR_FORMAT:format(highlight.bg) or nil
end

local function start_two_color_gradient()
    plugin_session.start(
        {
            renderer = "plain",
            gradient = {steps = CONFIGURED_STEPS, colors = {START_COLOR, END_COLOR}},
        }
    )
end

spec.describe(
    "gradient_palette",
    function()
        spec.it(
            "defines one foreground and one fill group per step",
            function()
                start_two_color_gradient()
                for step = 1, CONFIGURED_STEPS do
                    expect.truthy(
                        foreground_of(GRADIENT_PREFIX .. step),
                        ("foreground step %d defined"):format(step)
                    )
                    expect.truthy(
                        background_of(FILL_PREFIX .. step),
                        ("fill step %d defined"):format(step)
                    )
                end
            end
        )

        spec.it(
            "maps ratio endpoints to the configured colors",
            function()
                start_two_color_gradient()
                expect.equal(
                    foreground_of(gradient_palette.group_at(0)), START_COLOR, "start"
                )
                expect.equal(
                    foreground_of(gradient_palette.group_at(1)), END_COLOR, "end"
                )
                expect.equal(
                    gradient_palette.color_at(0), START_COLOR, "color at start"
                )
                expect.equal(gradient_palette.color_at(1), END_COLOR, "color at end")
            end
        )

        spec.it(
            "uses the fill variant groups when requested",
            function()
                plugin_session.start(
                    {
                        renderer = "plain",
                        gradient = {
                            colors = {START_COLOR, END_COLOR},
                            fill_foreground = FILL_FOREGROUND,
                        },
                    }
                )
                local fill_group = gradient_palette.group_at(0, "fill")
                expect.matches(fill_group, "^" .. FILL_PREFIX, "fill group name")
                expect.equal(background_of(fill_group), START_COLOR, "fill background")
                expect.equal(
                    foreground_of(fill_group), FILL_FOREGROUND, "fill foreground"
                )
            end
        )

        spec.it(
            "accepts a single color string as the whole gradient",
            function()
                expect.succeeds(
                    function()
                        plugin_session.start(
                            {
                                renderer = "plain",
                                gradient = {colors = SINGLE_COLOR},
                            }
                        )
                    end,
                    "setup with a single gradient color"
                )
                expect.equal(
                    foreground_of(gradient_palette.group_at(0)), SINGLE_COLOR, "start"
                )
                expect.equal(
                    foreground_of(gradient_palette.group_at(1)), SINGLE_COLOR, "end"
                )
            end
        )

        spec.it(
            "positions by column inside a total width",
            function()
                start_two_color_gradient()
                expect.equal(
                    gradient_palette.group_for_position(0, 10),
                    gradient_palette.group_at(0),
                    "first column"
                )
                expect.equal(
                    gradient_palette.group_for_position(9, 10),
                    gradient_palette.group_at(1),
                    "last column"
                )
                expect.equal(
                    gradient_palette.group_for_position(0, 1),
                    gradient_palette.group_at(0),
                    "single column"
                )
            end
        )
    end
)
