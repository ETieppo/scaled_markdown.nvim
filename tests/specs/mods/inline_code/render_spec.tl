local type ExtmarkEntryProps = require("helpers.types.extmark_entry_props")
local type InlineCodeConfigProps = require(
    "scaled_markdown.mods.inline_code.config_props"
)
local buffer_factory = require("helpers.buffer_factory")
local expect = require("harness.assertions")
local extmark_predicates = require("helpers.extmark_predicates")
local extmark_reader = require("helpers.extmark_reader")
local plugin_session = require("helpers.plugin_session")
local spec = require("harness.spec")

local MOD_NAME <const> = "inline_code"
local LINE <const> = "run `make test` now"
local CODE_SPAN_GROUP <const> = "ScaledMarkdownInlineCode"
local SPAN_START_COLUMN <const> = 4
local SPAN_END_COLUMN <const> = 15
local DELIMITER_COLUMNS <const>: {integer} = {4, 14}
local DEFAULT_REPLACEMENT <const> = " "

local function render(mod_config?: InlineCodeConfigProps): integer
    plugin_session.start_with_only(MOD_NAME, mod_config as {string: any})
    local buf = buffer_factory.from_lines({LINE})
    plugin_session.render(buf)
    return buf
end

spec.describe(
    "inline_code render",
    function()
        spec.it(
            "highlights the whole code span",
            function()
                local span = extmark_reader.find(
                    render(), extmark_predicates.with_highlight(CODE_SPAN_GROUP)
                )
                expect.truthy(span, "span extmark")
                expect.equal(span.col, SPAN_START_COLUMN, "span start")
                expect.equal(span.details.end_col, SPAN_END_COLUMN, "span end")
            end
        )

        spec.it(
            "replaces both backtick delimiters",
            function()
                local delimiters = extmark_reader.find_all(
                    render(), extmark_predicates.has_conceal
                )
                expect.equal(#delimiters, 2, "two delimiters")
                for _, delimiter in ipairs(delimiters) do
                    expect.equal(
                        delimiter.details.conceal, DEFAULT_REPLACEMENT, "replacement"
                    )
                end
                expect.deep_equal(
                    vim.tbl_map(
                        function(entry: ExtmarkEntryProps): integer
                            return entry.col
                        end,
                        delimiters
                    ),
                    DELIMITER_COLUMNS,
                    "delimiter columns"
                )
            end
        )

        spec.it(
            "uses the configured delimiter replacement",
            function()
                local delimiter = extmark_reader.find(
                    render({delimiter_replacement = ""}), extmark_predicates.has_conceal
                )
                expect.equal(delimiter.details.conceal, "", "hidden delimiter")
            end
        )
    end
)
