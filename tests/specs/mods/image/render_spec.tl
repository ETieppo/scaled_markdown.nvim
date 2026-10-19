local type ImageConfigProps = require("scaled_markdown.mods.image.config_props")
local buffer_factory = require("helpers.buffer_factory")
local conceal_reader = require("helpers.conceal_reader")
local expect = require("harness.assertions")
local extmark_predicates = require("helpers.extmark_predicates")
local extmark_reader = require("helpers.extmark_reader")
local plugin_session = require("helpers.plugin_session")
local spec = require("harness.spec")

local MOD_NAME <const> = "image"
local LINE <const> = "see ![A cat](./cat.png) here"
local DESCRIPTION_GROUP <const> = "ScaledMarkdownImageDescription"
local ICON_GROUP <const> = "ScaledMarkdownImageIcon"
local IMAGE_COLUMN <const> = 4
local CUSTOM_ICON <const> = "[img] "

local function render(lines: {string}, mod_config?: ImageConfigProps): integer
    plugin_session.start_with_only(MOD_NAME, mod_config as {string: any})
    local buf = buffer_factory.from_lines(lines)
    plugin_session.render(buf)
    return buf
end

spec.describe(
    "image render",
    function()
        spec.it(
            "shows only the description behind an icon",
            function()
                local buf = render({LINE})
                local mod_config = plugin_session.mod_config(MOD_NAME)
                    as ImageConfigProps
                expect.equal(
                    conceal_reader.visible_text(buf, 0), "see A cat here", "text"
                )
                local icon = extmark_reader.find(buf, extmark_predicates.is_inline)
                expect.equal(icon.col, IMAGE_COLUMN, "icon column")
                expect.deep_equal(
                    icon.details.virt_text,
                    {{mod_config.icon, ICON_GROUP}},
                    "icon chunk"
                )
            end
        )

        spec.it(
            "highlights the description",
            function()
                expect.equal(
                    conceal_reader.highlighted_text(
                        render({LINE}), 0, DESCRIPTION_GROUP
                    ),
                    "A cat",
                    "description"
                )
            end
        )

        spec.it(
            "skips images without a description",
            function()
                expect.equal(
                    #extmark_reader.list(render({"![](./cat.png)"})),
                    0,
                    "nothing rendered"
                )
            end
        )

        spec.it(
            "uses the configured icon",
            function()
                local buf = render({LINE}, {icon = CUSTOM_ICON})
                expect.equal(
                    extmark_reader.find(
                        buf, extmark_predicates.is_inline
                    ).details.virt_text[1][1],
                    CUSTOM_ICON,
                    "custom icon"
                )
            end
        )
    end
)
