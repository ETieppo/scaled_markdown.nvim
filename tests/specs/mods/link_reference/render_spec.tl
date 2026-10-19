local type LinkReferenceConfigProps = require(
    "scaled_markdown.mods.link_reference.config_props"
)
local buffer_factory = require("helpers.buffer_factory")
local conceal_reader = require("helpers.conceal_reader")
local expect = require("harness.assertions")
local extmark_predicates = require("helpers.extmark_predicates")
local extmark_reader = require("helpers.extmark_reader")
local plugin_session = require("helpers.plugin_session")
local spec = require("harness.spec")

local MOD_NAME <const> = "link_reference"
local LINE <const> = '[ref]: https://neovim.io "Title"'
local UNTITLED_LINE <const> = "[ref]: https://neovim.io"
local ICON_GROUP <const> = "ScaledMarkdownLinkReferenceIcon"
local LABEL_GROUP <const> = "ScaledMarkdownLinkReferenceLabel"
local DESTINATION_GROUP <const> = "ScaledMarkdownLinkReferenceDestination"
local TITLE_GROUP <const> = "ScaledMarkdownLinkReferenceTitle"

local function render(line: string): integer
    local buf = buffer_factory.from_lines({line})
    plugin_session.render(buf)
    return buf
end

spec.describe(
    "link_reference render",
    function()
        spec.before_each(function() plugin_session.start_with_only(MOD_NAME) end)

        spec.it(
            "adds the icon before the definition",
            function()
                local icon = extmark_reader.find(
                    render(LINE), extmark_predicates.is_inline
                )
                local mod_config = plugin_session.mod_config(MOD_NAME)
                    as LinkReferenceConfigProps
                expect.equal(icon.col, 0, "icon column")
                expect.deep_equal(
                    icon.details.virt_text,
                    {{mod_config.icon, ICON_GROUP}},
                    "icon chunk"
                )
            end
        )

        spec.it(
            "highlights label, destination and title",
            function()
                local buf = render(LINE)
                expect.equal(
                    conceal_reader.highlighted_text(buf, 0, LABEL_GROUP), "[ref]", "l"
                )
                expect.equal(
                    conceal_reader.highlighted_text(buf, 0, DESTINATION_GROUP),
                    "https://neovim.io",
                    "destination"
                )
                expect.equal(
                    conceal_reader.highlighted_text(buf, 0, TITLE_GROUP),
                    '"Title"',
                    "title"
                )
            end
        )

        spec.it(
            "handles definitions without a title",
            function()
                expect.is_nil(
                    extmark_reader.find(
                        render(UNTITLED_LINE),
                        extmark_predicates.with_highlight(TITLE_GROUP)
                    ),
                    "no title highlight"
                )
            end
        )
    end
)
