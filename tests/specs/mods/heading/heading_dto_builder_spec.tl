local type HeadingProps = require("scaled_markdown.mods.heading.heading_props")
local HEADING_QUERY = require("scaled_markdown.mods.heading.query")
local capture_builder = require("helpers.capture_builder")
local expect = require("harness.assertions")
local heading_dto_builder = require("scaled_markdown.mods.heading.heading_dto_builder")
local spec = require("harness.spec")

local MAX_ATX_LEVEL <const> = 6
local ATX_LINE_FORMAT <const> = "%s  Level %d  "
local ATX_TEXT_FORMAT <const> = "Level %d"
local ROWS_PER_HEADING <const> = 2

local function build_heading_dtos(lines: {string}): {HeadingProps}
    local captures, buf = capture_builder.from_lines(lines, HEADING_QUERY)
    local heading_dtos: {HeadingProps} = {}
    for _, capture_dto in ipairs(captures) do
        heading_dtos[#heading_dtos + 1] = heading_dto_builder.build(capture_dto, buf)
    end
    return heading_dtos
end

spec.describe(
    "heading_dto_builder",
    function()
        spec.it(
            "reads level and trimmed text of every atx level",
            function()
                local lines: {string} = {}
                for level = 1, MAX_ATX_LEVEL do
                    lines[#lines + 1] = ATX_LINE_FORMAT:format(
                        string.rep("#", level), level
                    )
                    lines[#lines + 1] = ""
                end
                local heading_dtos = build_heading_dtos(lines)
                expect.equal(#heading_dtos, MAX_ATX_LEVEL, "six headings")
                for level, heading_dto in ipairs(heading_dtos) do
                    expect.equal(heading_dto.level, level, "level")
                    expect.equal(
                        heading_dto.text, ATX_TEXT_FORMAT:format(level), "trimmed text"
                    )
                    expect.equal(heading_dto.row, (level - 1) * ROWS_PER_HEADING, "row")
                    expect.is_nil(heading_dto.underline_row, "no underline")
                end
            end
        )

        spec.it(
            "includes leading indentation in the heading node",
            function()
                local heading_dto = build_heading_dtos({"   # Indented"})[1]
                expect.equal(
                    heading_dto.start_col, 0, "indentation belongs to the node"
                )
                expect.equal(heading_dto.text, "Indented", "text")
            end
        )

        spec.it(
            "keeps the container column of nested headings",
            function()
                local heading_dto = build_heading_dtos({"> # Quoted"})[1]
                expect.equal(
                    heading_dto.start_col, 2, "start column after quote marker"
                )
                expect.equal(heading_dto.text, "Quoted", "text")
            end
        )

        spec.it(
            "reads setext headings with their underline row",
            function()
                local heading_dtos = build_heading_dtos(
                    {
                        "First Title",
                        "===========",
                        "",
                        "Second Title",
                        "------------",
                    }
                )
                expect.equal(#heading_dtos, 2, "two headings")
                expect.equal(heading_dtos[1].level, 1, "equals underline is level 1")
                expect.equal(heading_dtos[1].text, "First Title", "first text")
                expect.equal(heading_dtos[1].underline_row, 1, "first underline row")
                expect.equal(heading_dtos[2].level, 2, "dash underline is level 2")
                expect.equal(heading_dtos[2].underline_row, 4, "second underline row")
            end
        )

        spec.it(
            "uses only the first line of multi line setext content",
            function()
                local heading_dto = build_heading_dtos(
                    {"Line one", "line two", "===="}
                )[1]
                expect.equal(heading_dto.text, "Line one", "first line only")
                expect.equal(heading_dto.underline_row, 2, "underline row")
            end
        )

        spec.it(
            "returns nil for atx headings without content",
            function() expect.is_nil(build_heading_dtos({"#"})[1], "empty heading") end
        )
    end
)
