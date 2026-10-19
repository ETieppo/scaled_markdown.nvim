local expect = require("harness.assertions")
local spec = require("harness.spec")
local border_line_builder = require("scaled_markdown.core.border.border_line_builder")
local utf8_text = require("scaled_markdown.core.text.utf8_text")
local BOX_WIDTH <const> = 12

spec.describe(
    "border_line_builder",
    function()
        spec.it(
            "builds a plain top border of the exact width",
            function()
                expect.equal(
                    border_line_builder.build_top(BOX_WIDTH),
                    "╭" .. string.rep("─", BOX_WIDTH - 2) .. "╮",
                    "top"
                )
            end
        )

        spec.it(
            "embeds a title in the top border without changing width",
            function()
                local top = border_line_builder.build_top(BOX_WIDTH, "lua")
                expect.equal(top, "╭─ lua ────╮", "titled top")
                expect.equal(utf8_text.display_width(top), BOX_WIDTH, "width kept")
            end
        )

        spec.it(
            "builds a bottom border of the exact width",
            function()
                expect.equal(
                    border_line_builder.build_bottom(BOX_WIDTH),
                    "╰" .. string.rep("─", BOX_WIDTH - 2) .. "╯",
                    "bottom"
                )
            end
        )

        spec.it(
            "never produces negative widths",
            function()
                expect.equal(
                    border_line_builder.build_top(0), "╭╮", "zero width top"
                )
                expect.equal(
                    border_line_builder.build_bottom(1), "╰╯", "one width bottom"
                )
            end
        )

        spec.it(
            "builds grid lines with junctions between columns",
            function()
                expect.equal(
                    border_line_builder.build_grid_top({2, 3}),
                    "╭──┬───╮",
                    "top"
                )
                expect.equal(
                    border_line_builder.build_grid_separator({2, 3}),
                    "├──┼───┤",
                    "separator"
                )
                expect.equal(
                    border_line_builder.build_grid_bottom({2, 3}),
                    "╰──┴───╯",
                    "bottom"
                )
            end
        )

        spec.it(
            "exposes the vertical border character",
            function()
                expect.equal(border_line_builder.vertical(), "│", "vertical")
            end
        )
    end
)
