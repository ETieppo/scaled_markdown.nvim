local type ExtmarkEntryProps = require("helpers.types.extmark_entry_props")
local RENDERER_ENUM = require("scaled_markdown.core.enums.renderer_enum")
local type RendererEnum = RENDERER_ENUM.RendererEnum
local buffer_factory = require("helpers.buffer_factory")
local environment = require("helpers.environment")
local expect = require("harness.assertions")
local extmark_reader = require("helpers.extmark_reader")
local plugin_session = require("helpers.plugin_session")
local scaled_markdown = require("scaled_markdown")
local spec = require("harness.spec")

local FIXTURE_NAME <const> = "all_components.md"
local CENTER_FIXTURE_LINE <const> = 32
local CENTER_CURSOR <const> = "normal! zz"
local HEADING_MOD_NAME <const> = "heading"
local ORIGINAL_CONCEALLEVEL <const> = 0
local ATTACHED_CONCEALLEVEL <const> = 2
local FULL_REVEAL <const> = {cursor_line = true, visual_selection = true}
local RENDERER_ORDER <const>: {RendererEnum} = {
    RENDERER_ENUM.PLAIN,
    RENDERER_ENUM.TYPEFACE,
    RENDERER_ENUM.TOILET,
    RENDERER_ENUM.FIGLET,
}
local REQUIRED_EXECUTABLES_BY_RENDERER <const>: {RendererEnum: {string}} = {
    [RENDERER_ENUM.PLAIN] = {},
    [RENDERER_ENUM.TYPEFACE] = {"magick", "chafa", "fc-match"},
    [RENDERER_ENUM.TOILET] = {"toilet"},
    [RENDERER_ENUM.FIGLET] = {"figlet"},
}

local function open_centered_fixture(): integer
    local buf = buffer_factory.from_fixture(FIXTURE_NAME)
    vim.api.nvim_win_set_cursor(0, {CENTER_FIXTURE_LINE, 0})
    vim.cmd(CENTER_CURSOR)
    return buf
end

local function has_virtual_lines(entries: {ExtmarkEntryProps}): boolean
    for _, entry in ipairs(entries) do
        if entry.details.virt_lines and #entry.details.virt_lines > 0 then
            return true
        end
    end
    return false
end

local function skip_unless_renderer_available(renderer: RendererEnum)
    local executables = REQUIRED_EXECUTABLES_BY_RENDERER[renderer]
    spec.skip_unless(
        environment.has_executables(executables),
        environment.missing_reason(executables)
    )
end

local function assert_mod_renders_alone(
    buf: integer, mod_name: string, renderer: RendererEnum
)
    plugin_session.start_with_only(
        mod_name,
        {},
        {
            renderer = renderer,
            reveal = FULL_REVEAL,
        }
    )
    expect.truthy(plugin_session.render_until_settled(buf), mod_name .. " settled")
    local entries = extmark_reader.list(buf)
    expect.at_least(#entries, 1, mod_name .. " produced extmarks")
    if mod_name == HEADING_MOD_NAME then
        expect.equal(
            has_virtual_lines(entries),
            renderer ~= RENDERER_ENUM.PLAIN,
            "heading text art matches renderer"
        )
    end
end

spec.describe(
    "all components fixture",
    function()
        for _, renderer in ipairs(RENDERER_ORDER) do
            spec.describe(
                ("renderer %s"):format(renderer),
                function()
                    spec.it(
                        "renders every mod on its own",
                        function()
                            skip_unless_renderer_available(renderer)
                            local buf = open_centered_fixture()
                            plugin_session.start({renderer = renderer})
                            for _, mod_name in ipairs(plugin_session.mod_names()) do
                                assert_mod_renders_alone(buf, mod_name, renderer)
                            end
                        end
                    )

                    spec.it(
                        "renders every mod together without errors",
                        function()
                            skip_unless_renderer_available(renderer)
                            local buf = open_centered_fixture()
                            plugin_session.start({renderer = renderer})
                            expect.truthy(
                                plugin_session.render_until_settled(buf), "settled"
                            )
                            expect.at_least(#extmark_reader.list(buf), 1, "extmarks")
                        end
                    )
                end
            )
        end

        spec.it(
            "never changes the buffer text",
            function()
                local buf = open_centered_fixture()
                local original_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
                plugin_session.start()
                plugin_session.render_until_settled(buf)
                expect.deep_equal(
                    vim.api.nvim_buf_get_lines(buf, 0, -1, false),
                    original_lines,
                    "plain markdown kept"
                )
                expect.falsy(vim.bo[buf].modified, "buffer not modified")
            end
        )

        spec.it(
            "cleans every extmark and window option on disable",
            function()
                vim.wo.conceallevel = ORIGINAL_CONCEALLEVEL
                local buf = open_centered_fixture()
                plugin_session.start()
                expect.equal(
                    vim.wo.conceallevel, ATTACHED_CONCEALLEVEL, "attached window"
                )
                scaled_markdown.disable(buf)
                expect.equal(#extmark_reader.list(buf), 0, "extmarks cleared")
                expect.equal(vim.wo.conceallevel, ORIGINAL_CONCEALLEVEL, "restored")
            end
        )
    end
)
