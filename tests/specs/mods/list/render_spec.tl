local type ExtmarkEntryProps = require("helpers.types.extmark_entry_props")
local type ListConfigProps = require("scaled_markdown.mods.list.config_props")
local buffer_factory = require("helpers.buffer_factory")
local expect = require("harness.assertions")
local extmark_predicates = require("helpers.extmark_predicates")
local extmark_reader = require("helpers.extmark_reader")
local plugin_session = require("helpers.plugin_session")
local spec = require("harness.spec")

local MOD_NAME <const> = "list"
local BULLET_GROUP <const> = "ScaledMarkdownListBullet"
local ORDERED_GROUP <const> = "ScaledMarkdownListOrdered"
local INDENTED_BULLET_COLUMN <const> = 2
local CUSTOM_BULLET <const> = ">"
local BULLET_ROWS <const>: {integer} = {0, 2, 4}
local NESTED_LINES <const>: {string} = {
    "- level one",
    "  - level two",
    "    - level three",
    "      - level four",
    "        - level five",
}

local function render(lines: {string}, mod_config?: ListConfigProps): integer
    plugin_session.start_with_only(MOD_NAME, mod_config as {string: any})
    local buf = buffer_factory.from_lines(lines)
    plugin_session.render(buf)
    return buf
end

local function bullet_on_row(buf: integer, row: integer): ExtmarkEntryProps
    return extmark_reader.find(buf, extmark_predicates.overlay_on_row(row))
end

local function bullets(): {string}
    return (plugin_session.mod_config(MOD_NAME) as ListConfigProps).bullets
end

spec.describe(
    "list render",
    function()
        spec.it(
            "overlays the bullet character at its column",
            function()
                local bullet = bullet_on_row(render({"  - indented"}), 0)
                expect.equal(bullet.col, INDENTED_BULLET_COLUMN, "bullet column")
                expect.deep_equal(
                    bullet.details.virt_text,
                    {{bullets()[1], BULLET_GROUP}},
                    "bullet chunk"
                )
            end
        )

        spec.it(
            "cycles bullets by nesting depth",
            function()
                local buf = render(NESTED_LINES)
                local configured_bullets = bullets()
                for row = 0, #NESTED_LINES - 1 do
                    expect.equal(
                        bullet_on_row(buf, row).details.virt_text[1][1],
                        configured_bullets[row % #configured_bullets + 1],
                        ("depth %d bullet"):format(row + 1)
                    )
                end
            end
        )

        spec.it(
            "replaces minus, plus and star markers",
            function()
                local buf = render({"- a", "", "+ b", "", "* c"})
                for _, row in ipairs(BULLET_ROWS) do
                    expect.truthy(
                        bullet_on_row(buf, row), ("bullet on row %d"):format(row)
                    )
                end
            end
        )

        spec.it(
            "highlights ordered markers without replacing them",
            function()
                local buf = render({"1. one", "2) two"})
                local ordered = extmark_reader.find_all(
                    buf, extmark_predicates.with_highlight(ORDERED_GROUP)
                )
                expect.equal(#ordered, 2, "two ordered markers")
                expect.is_nil(bullet_on_row(buf, 0), "no overlay for ordered")
            end
        )

        spec.it(
            "uses the configured bullets",
            function()
                local buf = render({"- a", "  - b"}, {bullets = {CUSTOM_BULLET}})
                expect.equal(
                    bullet_on_row(buf, 0).details.virt_text[1][1], CUSTOM_BULLET, "1"
                )
                expect.equal(
                    bullet_on_row(buf, 1).details.virt_text[1][1], CUSTOM_BULLET, "2"
                )
            end
        )
    end
)
