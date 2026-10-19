local type WindowOptionsProps = require(
    "scaled_markdown.core.types.window_options_props"
)
local buffer_factory = require("helpers.buffer_factory")
local expect = require("harness.assertions")
local spec = require("harness.spec")
local window_option_guard = require("scaled_markdown.core.window.window_option_guard")

local OPTIONS <const>: WindowOptionsProps = {conceallevel = 2, concealcursor = "nc"}
local ORIGINAL_CONCEALLEVEL <const> = 1
local OVERRIDE_CONCEALLEVEL <const> = 3
local INVALID_WINDOW <const> = 99999

spec.describe(
    "window_option_guard",
    function()
        spec.before_each(function() buffer_factory.from_lines({"a"}) end)

        spec.after_each(
            function() window_option_guard.restore(vim.api.nvim_get_current_win()) end
        )

        spec.it(
            "applies options locally to the window",
            function()
                local win = vim.api.nvim_get_current_win()
                window_option_guard.apply(win, OPTIONS)
                expect.equal(vim.wo[win].conceallevel, 2, "conceallevel")
                expect.equal(vim.wo[win].concealcursor, "nc", "concealcursor")
            end
        )

        spec.it(
            "restores the original values",
            function()
                local win = vim.api.nvim_get_current_win()
                vim.wo[win].conceallevel = ORIGINAL_CONCEALLEVEL
                window_option_guard.apply(win, OPTIONS)
                window_option_guard.restore(win)
                expect.equal(
                    vim.wo[win].conceallevel, ORIGINAL_CONCEALLEVEL, "restored"
                )
                expect.equal(vim.wo[win].concealcursor, "", "concealcursor restored")
            end
        )

        spec.it(
            "keeps the first saved value across repeated applies",
            function()
                local win = vim.api.nvim_get_current_win()
                vim.wo[win].conceallevel = ORIGINAL_CONCEALLEVEL
                window_option_guard.apply(win, OPTIONS)
                window_option_guard.apply(win, {conceallevel = OVERRIDE_CONCEALLEVEL})
                window_option_guard.restore(win)
                expect.equal(
                    vim.wo[win].conceallevel, ORIGINAL_CONCEALLEVEL, "original"
                )
            end
        )

        spec.it(
            "ignores invalid windows",
            function()
                expect.succeeds(
                    function()
                        window_option_guard.apply(INVALID_WINDOW, OPTIONS)
                        window_option_guard.restore(INVALID_WINDOW)
                    end,
                    "invalid window"
                )
            end
        )

        spec.it(
            "restores only once",
            function()
                local win = vim.api.nvim_get_current_win()
                window_option_guard.apply(win, OPTIONS)
                window_option_guard.restore(win)
                vim.wo[win].conceallevel = OVERRIDE_CONCEALLEVEL
                window_option_guard.restore(win)
                expect.equal(
                    vim.wo[win].conceallevel,
                    OVERRIDE_CONCEALLEVEL,
                    "second restore is a no-op"
                )
            end
        )
    end
)
