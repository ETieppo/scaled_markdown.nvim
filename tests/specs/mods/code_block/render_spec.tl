local type CodeBlockConfigProps = require(
    "scaled_markdown.mods.code_block.config_props"
)
local type ExtmarkEntryProps = require("helpers.types.extmark_entry_props")
local buffer_factory = require("helpers.buffer_factory")
local expect = require("harness.assertions")
local extmark_predicates = require("helpers.extmark_predicates")
local extmark_reader = require("helpers.extmark_reader")
local plugin_session = require("helpers.plugin_session")
local spec = require("harness.spec")
local utf8_text = require("scaled_markdown.core.text.utf8_text")

local MOD_NAME <const> = "code_block"
local FENCED_LINES <const>: {string} = {"```lua", "local a = 1", "```"}
local INDENTED_LINES <const>: {string} = {"para", "", "    code one", "    code two"}
local MIN_WIDTH <const> = 20
local EXTRA_CONTENT_WIDTH <const> = 10
local HUGE_CONTENT_WIDTH <const> = 500
local BORDERS_AND_PADDING_WIDTH <const> = 4
local CONTENT_ROW <const> = 1
local VERTICAL_BORDER <const> = "│"

local function render(lines: {string}): integer
    local mod_config: CodeBlockConfigProps = {min_width = MIN_WIDTH}
    plugin_session.start_with_only(MOD_NAME, mod_config as {string: any})
    local buf = buffer_factory.from_lines(lines)
    plugin_session.render(buf)
    return buf
end

local function overlay_text_on_row(buf: integer, row: integer): string
    local entry = extmark_reader.find(buf, extmark_predicates.overlay_on_row(row))
    return entry and extmark_reader.virt_text_string(entry.details)
end

local function box_width_on_row(buf: integer, row: integer): integer
    return utf8_text.display_width(vim.trim(overlay_text_on_row(buf, row)))
end

spec.describe(
    "code_block render",
    function()
        spec.it(
            "turns the fences into a titled top and a bottom border",
            function()
                local buf = render(FENCED_LINES)
                expect.truthy(
                    vim.startswith(overlay_text_on_row(buf, 0), "╭─ lua "), "top"
                )
                expect.truthy(
                    vim.startswith(overlay_text_on_row(buf, 2), "╰─"), "bottom"
                )
                expect.equal(box_width_on_row(buf, 0), MIN_WIDTH, "top width")
                expect.equal(box_width_on_row(buf, 2), MIN_WIDTH, "bottom width")
            end
        )

        spec.it(
            "adds side borders to every content row",
            function()
                local buf = render(FENCED_LINES)
                local left = extmark_reader.find(
                    buf, extmark_predicates.inline_on_row(CONTENT_ROW)
                )
                local right = extmark_reader.find(
                    buf,
                    function(
                        details: vim.ExtmarkOptionsProps, entry: ExtmarkEntryProps
                    ): boolean
                        return entry.row == CONTENT_ROW
                            and details.virt_text_win_col ~= nil
                    end
                )
                expect.equal(
                    left.details.virt_text[1][1], VERTICAL_BORDER, "left border"
                )
                expect.equal(left.details.virt_text[2][1], " ", "padding")
                expect.equal(
                    right.details.virt_text[1][1], VERTICAL_BORDER, "right border"
                )
                expect.equal(
                    right.details.virt_text_win_col, MIN_WIDTH - 1, "right column"
                )
            end
        )

        spec.it(
            "grows the box to fit the widest content line",
            function()
                local long_line = string.rep("x", MIN_WIDTH + EXTRA_CONTENT_WIDTH)
                expect.equal(
                    box_width_on_row(render({"```", long_line, "```"}), 0),
                    #long_line + BORDERS_AND_PADDING_WIDTH,
                    "content plus borders"
                )
            end
        )

        spec.it(
            "never exceeds the window text area",
            function()
                local buf = render({"```", string.rep("x", HUGE_CONTENT_WIDTH), "```"})
                expect.truthy(
                    box_width_on_row(buf, 0) <= vim.api.nvim_win_get_width(0),
                    "clamped to window"
                )
            end
        )

        spec.it(
            "draws virtual borders around indented blocks",
            function()
                local buf = render(INDENTED_LINES)
                local above = extmark_reader.find(
                    buf, extmark_predicates.virt_lines_above
                )
                local below = extmark_reader.find(
                    buf, extmark_predicates.virt_lines_below
                )
                expect.equal(above.row, 2, "top border above first row")
                expect.equal(below.row, 3, "bottom border below last row")
                expect.matches(
                    extmark_reader.virt_line_string(above.details.virt_lines[1]),
                    "╭",
                    "top"
                )
                expect.matches(
                    extmark_reader.virt_line_string(below.details.virt_lines[1]),
                    "╰",
                    "bottom"
                )
            end
        )

        spec.it(
            "renders empty fenced blocks without errors",
            function()
                local buf = render({"```", "```"})
                expect.truthy(overlay_text_on_row(buf, 0), "top border")
                expect.truthy(overlay_text_on_row(buf, 1), "bottom border")
            end
        )
    end
)
