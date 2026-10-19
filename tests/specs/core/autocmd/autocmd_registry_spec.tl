local expect = require("harness.assertions")
local spec = require("harness.spec")
local buffer_factory = require("helpers.buffer_factory")
local plugin_session = require("helpers.plugin_session")
local buffer_attachment = require("scaled_markdown.core.buffer.buffer_attachment")
local LINES <const>: {string} = {"# Title"}
local AUGROUP_NAME <const> = "ScaledMarkdown"
local OTHER_FILETYPE <const> = "lua"

spec.describe(
    "autocmd_registry",
    function()
        spec.it(
            "auto attaches buffers of configured file types",
            function()
                plugin_session.start()
                local buf = buffer_factory.from_lines(LINES)
                expect.truthy(buffer_attachment.is_attached(buf), "markdown attached")
            end
        )

        spec.it(
            "ignores other file types",
            function()
                plugin_session.start()
                vim.cmd.enew()
                local buf = vim.api.nvim_get_current_buf()
                vim.bo[buf].filetype = OTHER_FILETYPE
                expect.falsy(buffer_attachment.is_attached(buf), "lua ignored")
            end
        )

        spec.it(
            "does not auto attach when the plugin is disabled",
            function()
                plugin_session.start({renderer = "plain", enabled = false})
                local buf = buffer_factory.from_lines(LINES)
                expect.falsy(buffer_attachment.is_attached(buf), "not attached")
            end
        )

        spec.it(
            "attaches markdown buffers opened before setup",
            function()
                local buf = buffer_factory.from_lines(LINES)
                plugin_session.start()
                expect.truthy(
                    buffer_attachment.is_attached(buf), "existing buffer attached"
                )
            end
        )

        spec.it(
            "registers a single global augroup across repeated setups",
            function()
                plugin_session.start()
                plugin_session.start()
                local file_type_autocmds = vim.api.nvim_get_autocmds(
                    {group = AUGROUP_NAME, event = "FileType"}
                )
                expect.equal(#file_type_autocmds, 1, "single FileType autocmd")
            end
        )
    end
)
