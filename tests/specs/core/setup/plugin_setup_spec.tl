local expect = require("harness.assertions")
local spec = require("harness.spec")
local stub = require("harness.stub")
local buffer_factory = require("helpers.buffer_factory")
local plugin_session = require("helpers.plugin_session")
local scaled_markdown = require("scaled_markdown")
local buffer_attachment = require("scaled_markdown.core.buffer.buffer_attachment")
local render_pipeline = require("scaled_markdown.core.render.render_pipeline")
local text_art_service = require("scaled_markdown.core.text_art.text_art_service")

local EXPECTED_MOD_NAMES <const>: {string} = {
    "heading",
    "text",
    "inline_code",
    "link",
    "link_reference",
    "image",
    "list",
    "checkbox",
    "quote",
    "code_block",
    "table",
    "thematic_break",
}
local MOD_HIGHLIGHT_GROUP <const> = "ScaledMarkdownTextEmphasis"
local GRADIENT_GROUP <const> = "ScaledMarkdownGradient1"
local REFRESH_WAIT_MS <const> = 1000

local function is_highlight_defined(group_name: string): boolean
    local highlight = vim.api.nvim_get_hl(0, {name = group_name})
    return next(highlight as {string: any}) ~= nil
end

spec.describe(
    "plugin_setup",
    function()
        spec.it(
            "registers every mod from the entry point in order",
            function()
                plugin_session.start()
                expect.deep_equal(
                    plugin_session.mod_names(), EXPECTED_MOD_NAMES, "mods"
                )
            end
        )

        spec.it(
            "works with an empty or missing user config",
            function()
                expect.succeeds(function() scaled_markdown.setup({}) end, "empty")
                expect.succeeds(function() scaled_markdown.setup() end, "nil")
            end
        )

        spec.it(
            "defines gradient and mod highlight groups",
            function()
                plugin_session.start()
                expect.truthy(is_highlight_defined(GRADIENT_GROUP), "gradient group")
                expect.truthy(is_highlight_defined(MOD_HIGHLIGHT_GROUP), "mod group")
            end
        )

        spec.it(
            "redefines highlights and clears art after a colorscheme change",
            function()
                plugin_session.start()
                local clear_calls = stub.spy(text_art_service, "clear_cache")
                vim.cmd("hi clear")
                vim.api.nvim_exec_autocmds("ColorScheme", {})
                expect.equal(#clear_calls, 1, "cache cleared")
                expect.truthy(
                    is_highlight_defined(GRADIENT_GROUP), "gradient redefined"
                )
            end
        )

        spec.it(
            "re-renders attached buffers when text art becomes ready",
            function()
                plugin_session.start()
                local buf = buffer_factory.from_lines({"# Title"})
                local calls = stub.spy(render_pipeline, "render")
                buffer_attachment.schedule_refresh_all()
                expect.truthy(
                    vim.wait(
                        REFRESH_WAIT_MS, function(): boolean return #calls > 0 end
                    ),
                    "scheduled refresh rendered"
                )
                expect.equal(calls[1][1], buf, "attached buffer rendered")
            end
        )
    end
)
