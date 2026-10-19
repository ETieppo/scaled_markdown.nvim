local expect = require("harness.assertions")
local spec = require("harness.spec")
local color_math = require("scaled_markdown.core.highlight.color_math")

local RED <const> = "#ff0000"
local BLUE <const> = "#0000ff"
local GREEN <const> = "#00ff00"
local MIDPOINT_RED_BLUE <const> = "#800080"
local SINGLE_STOP_RATIOS <const>: {number} = {0, 0.25, 0.5, 1}

spec.describe(
    "color_math",
    function()
        spec.describe(
            "hex_to_rgb",
            function()
                spec.it(
                    "parses lower and upper case hex",
                    function()
                        expect.deep_equal(
                            color_math.hex_to_rgb("#ff8000"), {255, 128, 0}, "lower"
                        )
                        expect.deep_equal(
                            color_math.hex_to_rgb("#FF8000"), {255, 128, 0}, "upper"
                        )
                    end
                )

                spec.it(
                    "rejects malformed colors",
                    function()
                        expect.fails(
                            function() color_math.hex_to_rgb("ff0000") end,
                            "invalid hex color",
                            "missing hash"
                        )
                        expect.fails(
                            function() color_math.hex_to_rgb("#fff") end,
                            "invalid hex color",
                            "short form"
                        )
                    end
                )
            end
        )

        spec.describe(
            "rgb_to_hex",
            function()
                spec.it(
                    "formats zero padded lower case hex",
                    function()
                        expect.equal(
                            color_math.rgb_to_hex({1, 2, 255}), "#0102ff", "formatted"
                        )
                    end
                )
            end
        )

        spec.describe(
            "interpolate_hex",
            function()
                spec.it(
                    "returns the endpoints at ratio 0 and 1",
                    function()
                        expect.equal(
                            color_math.interpolate_hex({RED, BLUE}, 0), RED, "start"
                        )
                        expect.equal(
                            color_math.interpolate_hex({RED, BLUE}, 1), BLUE, "end"
                        )
                    end
                )

                spec.it(
                    "blends linearly between two stops",
                    function()
                        expect.equal(
                            color_math.interpolate_hex({RED, BLUE}, 0.5),
                            MIDPOINT_RED_BLUE,
                            "midpoint"
                        )
                    end
                )

                spec.it(
                    "clamps ratios outside 0..1",
                    function()
                        expect.equal(
                            color_math.interpolate_hex({RED, BLUE}, -3), RED, "below"
                        )
                        expect.equal(
                            color_math.interpolate_hex({RED, BLUE}, 7), BLUE, "above"
                        )
                    end
                )

                spec.it(
                    "walks every stop of a multi stop gradient",
                    function()
                        expect.equal(
                            color_math.interpolate_hex({RED, GREEN, BLUE}, 0.5),
                            GREEN,
                            "middle stop"
                        )
                    end
                )

                spec.it(
                    "returns a single stop unchanged for any ratio",
                    function()
                        for _, ratio in ipairs(SINGLE_STOP_RATIOS) do
                            expect.equal(
                                color_math.interpolate_hex({RED}, ratio),
                                RED,
                                ("single stop at %s"):format(tostring(ratio))
                            )
                        end
                    end
                )
            end
        )
    end
)
