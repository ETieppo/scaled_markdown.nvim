local expect = require("harness.assertions")
local spec = require("harness.spec")
local text_art_line_wrapper = require(
    "scaled_markdown.core.text_art.text_art_line_wrapper"
)

local COLUMNS_PER_CHARACTER <const> = 4
local UNBOUNDED_WIDTH <const> = 1000

local function rendered_width(text: string): integer
    return #text * COLUMNS_PER_CHARACTER
end

spec.describe(
    "text_art_line_wrapper",
    function()
        spec.it(
            "keeps text that already fits on one line",
            function()
                local text = "one two"
                expect.deep_equal(
                    text_art_line_wrapper.wrap(
                        text, rendered_width(text), rendered_width(text)
                    ),
                    {text},
                    "single line"
                )
            end
        )

        spec.it(
            "breaks between words using the rendered scale",
            function()
                local text = "one two three"
                expect.deep_equal(
                    text_art_line_wrapper.wrap(
                        text, rendered_width(text), rendered_width("one two")
                    ),
                    {"one two", "three"},
                    "wrapped"
                )
            end
        )

        spec.it(
            "keeps an oversized single word on its own line",
            function()
                local text = "tiny enormousword"
                expect.deep_equal(
                    text_art_line_wrapper.wrap(
                        text, rendered_width(text), rendered_width("tiny")
                    ),
                    {"tiny", "enormousword"},
                    "oversized word"
                )
            end
        )

        spec.it(
            "collapses repeated whitespace between words",
            function()
                expect.deep_equal(
                    text_art_line_wrapper.wrap(
                        "a    b", UNBOUNDED_WIDTH, UNBOUNDED_WIDTH
                    ),
                    {"a b"},
                    "collapsed"
                )
            end
        )

        spec.it(
            "returns no lines for blank text",
            function()
                expect.deep_equal(
                    text_art_line_wrapper.wrap("   ", 10, 10), {}, "blank"
                )
            end
        )
    end
)
