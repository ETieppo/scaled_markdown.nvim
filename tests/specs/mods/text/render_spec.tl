local type TextConfigProps = require("scaled_markdown.mods.text.config_props")
local buffer_factory = require("helpers.buffer_factory")
local conceal_reader = require("helpers.conceal_reader")
local expect = require("harness.assertions")
local extmark_reader = require("helpers.extmark_reader")
local plugin_session = require("helpers.plugin_session")
local spec = require("harness.spec")

local MOD_NAME <const> = "text"
local LINE <const> = "a *em* b **strong** c ~~gone~~"
local EMPHASIS_GROUP <const> = "ScaledMarkdownTextEmphasis"
local STRONG_GROUP <const> = "ScaledMarkdownTextStrongEmphasis"
local STRIKETHROUGH_GROUP <const> = "ScaledMarkdownTextStrikethrough"
local ALL_DELIMITERS <const>: {string} = {
    "*", "*", "*", "*", "*", "*", "~", "~", "~", "~"
}

local type RangeProps = {integer, integer}

local function highlight_ranges(buf: integer): {string: {RangeProps}}
    local ranges: {string: {RangeProps}} = {}
    for _, entry in ipairs(extmark_reader.list(buf)) do
        local group = entry.details.hl_group
        if group then
            ranges[group] = ranges[group] or {}
            table.insert(ranges[group], {entry.col, entry.details.end_col})
        end
    end
    return ranges
end

local function render(mod_config?: TextConfigProps): integer
    plugin_session.start_with_only(MOD_NAME, mod_config as {string: any})
    local buf = buffer_factory.from_lines({LINE})
    plugin_session.render(buf)
    return buf
end

spec.describe(
    "text render",
    function()
        spec.it(
            "highlights emphasis, strong emphasis and strikethrough spans",
            function()
                local ranges = highlight_ranges(render())
                expect.deep_equal(ranges[EMPHASIS_GROUP], {{2, 6}}, "emphasis span")
                expect.deep_equal(ranges[STRONG_GROUP], {{9, 19}}, "strong span")
                expect.contains(ranges[STRIKETHROUGH_GROUP], {22, 30}, "strike span")
            end
        )

        spec.it(
            "conceals every delimiter by default",
            function()
                expect.deep_equal(
                    conceal_reader.concealed_texts(render(), 0),
                    ALL_DELIMITERS,
                    "delimiters"
                )
            end
        )

        spec.it(
            "keeps delimiters visible when conceal is disabled",
            function()
                local buf = render({conceal_delimiters = false})
                expect.deep_equal(
                    conceal_reader.concealed_texts(buf, 0), {}, "nothing hidden"
                )
                expect.truthy(
                    highlight_ranges(buf)[EMPHASIS_GROUP], "still highlighted"
                )
            end
        )

        spec.it(
            "defines its highlight groups",
            function()
                plugin_session.start_with_only(MOD_NAME)
                expect.truthy(
                    vim.api.nvim_get_hl(0, {name = EMPHASIS_GROUP}).italic, "italic"
                )
                expect.truthy(
                    vim.api.nvim_get_hl(0, {name = STRONG_GROUP}).bold, "bold"
                )
                expect.truthy(
                    vim.api.nvim_get_hl(0, {name = STRIKETHROUGH_GROUP}).strikethrough,
                    "strikethrough"
                )
            end
        )
    end
)
