local expect = require("harness.assertions")
local spec = require("harness.spec")
local utf8_text = require("scaled_markdown.core.text.utf8_text")
local graphics_placeholder_builder = require(
    "scaled_markdown.core.text_art.graphics_placeholder_builder"
)

local PLACEHOLDER <const> = vim.fn.nr2char(0x10EEEE)
local FIRST_ROW_DIACRITIC <const> = vim.fn.nr2char(0x0305)
local SECOND_ROW_DIACRITIC <const> = vim.fn.nr2char(0x030D)
local COLUMNS <const> = 5
local ROWS <const> = 2
local EXTRA_ROWS <const> = 10

spec.describe(
    "graphics_placeholder_builder",
    function()
        spec.it(
            "builds one line per image row",
            function()
                expect.equal(
                    #graphics_placeholder_builder.build_lines(COLUMNS, ROWS),
                    ROWS,
                    "line count"
                )
            end
        )

        spec.it(
            "marks each row with its diacritic after the first cell",
            function()
                local lines = graphics_placeholder_builder.build_lines(COLUMNS, ROWS)
                expect.truthy(
                    vim.startswith(lines[1], PLACEHOLDER .. FIRST_ROW_DIACRITIC),
                    "first row diacritic"
                )
                expect.truthy(
                    vim.startswith(lines[2], PLACEHOLDER .. SECOND_ROW_DIACRITIC),
                    "second row diacritic"
                )
            end
        )

        spec.it(
            "fills exactly the requested number of columns",
            function()
                local lines = graphics_placeholder_builder.build_lines(COLUMNS, ROWS)
                local _, placeholder_count = lines[1]:gsub(PLACEHOLDER, "")
                expect.equal(placeholder_count, COLUMNS, "placeholder cells")
                expect.equal(
                    utf8_text.display_width(lines[1]), COLUMNS, "display width"
                )
            end
        )

        spec.it(
            "caps rows at the number of available diacritics",
            function()
                local max_rows = graphics_placeholder_builder.max_rows()
                expect.equal(
                    #graphics_placeholder_builder.build_lines(
                        COLUMNS, max_rows + EXTRA_ROWS
                    ),
                    max_rows,
                    "capped rows"
                )
            end
        )
    end
)
