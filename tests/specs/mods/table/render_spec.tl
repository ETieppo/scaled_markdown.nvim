local type TableConfigProps = require("scaled_markdown.mods.table.config_props")
local buffer_factory = require("helpers.buffer_factory")
local expect = require("harness.assertions")
local extmark_predicates = require("helpers.extmark_predicates")
local extmark_reader = require("helpers.extmark_reader")
local plugin_session = require("helpers.plugin_session")
local spec = require("harness.spec")
local utf8_text = require("scaled_markdown.core.text.utf8_text")

local MOD_NAME <const> = "table"
local TABLE_LINES <const>: {string} = {
    "| Name | Value | Notes |",
    "| :--- | :---: | ----: |",
    "| alpha | 1 | first |",
}
local HEADER_GROUP <const> = "ScaledMarkdownTableHeaderCell"
local BODY_GROUP <const> = "ScaledMarkdownTableBodyCell"
local WIDE_SOURCE_LINE <const> = "| a      |      b |"

local function render(lines: {string}, mod_config?: TableConfigProps): integer
    plugin_session.start_with_only(MOD_NAME, mod_config as {string: any})
    local buf = buffer_factory.from_lines(lines)
    plugin_session.render(buf)
    return buf
end

local function overlay_details(buf: integer, row: integer): vim.ExtmarkOptionsProps
    return extmark_reader.find(buf, extmark_predicates.overlay_on_row(row)).details
end

local function row_text(buf: integer, row: integer): string
    return vim.trim(extmark_reader.virt_text_string(overlay_details(buf, row)))
end

local function row_groups(buf: integer, row: integer): {string}
    return vim.tbl_map(
        function(chunk: vim.VirtualChunkProps): string return chunk[2] end,
        overlay_details(buf, row).virt_text
    )
end

spec.describe(
    "table render",
    function()
        spec.it(
            "draws aligned cells between vertical borders",
            function()
                local buf = render(TABLE_LINES)
                expect.equal(
                    row_text(buf, 0), "│ Name  │ Value │ Notes │", "header row"
                )
                expect.equal(
                    row_text(buf, 2),
                    "│ alpha │   1   │ first │",
                    "aligned body"
                )
            end
        )

        spec.it(
            "turns the delimiter row into a grid separator",
            function()
                expect.equal(
                    row_text(render(TABLE_LINES), 1),
                    "├───────┼───────┼───────┤",
                    "separator"
                )
            end
        )

        spec.it(
            "uses header and body cell groups",
            function()
                local buf = render(TABLE_LINES)
                expect.contains(row_groups(buf, 0), HEADER_GROUP, "header group")
                expect.contains(row_groups(buf, 2), BODY_GROUP, "body group")
            end
        )

        spec.it(
            "adds top and bottom borders as virtual lines",
            function()
                local buf = render(TABLE_LINES)
                local top = extmark_reader.find(
                    buf, extmark_predicates.virt_lines_above
                )
                local bottom = extmark_reader.find(
                    buf, extmark_predicates.virt_lines_below
                )
                expect.equal(top.row, 0, "top above header")
                expect.equal(bottom.row, #TABLE_LINES - 1, "bottom below last row")
                expect.matches(
                    extmark_reader.virt_line_string(top.details.virt_lines[1]),
                    "╭───────┬───────┬───────╮",
                    "top line"
                )
                expect.matches(
                    extmark_reader.virt_line_string(bottom.details.virt_lines[1]),
                    "╰───────┴───────┴───────╯",
                    "bottom line"
                )
            end
        )

        spec.it(
            "covers the whole source line of short rendered rows",
            function()
                local buf = render(
                    {WIDE_SOURCE_LINE, "| - | - |"},
                    {cell_padding = 0, min_column_width = 1}
                )
                expect.at_least(
                    utf8_text.display_width(
                        extmark_reader.virt_text_string(overlay_details(buf, 0))
                    ),
                    utf8_text.display_width(WIDE_SOURCE_LINE),
                    "source hidden"
                )
            end
        )
    end
)
