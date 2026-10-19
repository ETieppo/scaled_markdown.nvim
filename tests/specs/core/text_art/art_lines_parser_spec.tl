local expect = require("harness.assertions")
local spec = require("harness.spec")
local art_lines_parser = require("scaled_markdown.core.text_art.art_lines_parser")

spec.describe(
    "art_lines_parser",
    function()
        spec.it(
            "splits stdout and drops the trailing newline",
            function()
                expect.deep_equal(
                    art_lines_parser.split_lines("a\nb\n"), {"a", "b"}, "lines"
                )
            end
        )

        spec.it(
            "treats missing stdout as empty",
            function()
                expect.deep_equal(art_lines_parser.split_lines(nil), {}, "nil stdout")
            end
        )

        spec.it(
            "trims blank lines at both edges only",
            function()
                expect.deep_equal(
                    art_lines_parser.trim_blank_edges({"  ", "a", " ", "b", "", "\t"}),
                    {"a", " ", "b"},
                    "trimmed"
                )
            end
        )

        spec.it(
            "returns an empty list when every line is blank",
            function()
                expect.deep_equal(
                    art_lines_parser.trim_blank_edges({" ", ""}), {}, "empty"
                )
            end
        )

        spec.it(
            "wraps non empty lines into a result and rejects empty ones",
            function()
                expect.deep_equal(
                    art_lines_parser.to_result({"x"}), {lines = {"x"}}, "result"
                )
                expect.is_nil(art_lines_parser.to_result({}), "empty result")
            end
        )
    end
)
