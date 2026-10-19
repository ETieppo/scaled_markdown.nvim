local expect = require("harness.assertions")
local spec = require("harness.spec")
local stub = require("harness.stub")
local terminal_capability = require("scaled_markdown.core.terminal.terminal_capability")

local ENVIRONMENT_NAMES <const>: {string} = {
    "TMUX", "TERM", "TERM_PROGRAM", "KITTY_WINDOW_ID"
}
local FAKE_UIS <const>: {any} = {{chan = 1}}
local CAPABLE_ENVIRONMENTS <const>: {string: {string: string}} = {
    kitty_window = {KITTY_WINDOW_ID = "1"},
    ghostty_program = {TERM_PROGRAM = "ghostty"},
    wezterm_program = {TERM_PROGRAM = "WezTerm"},
    kitty_term = {TERM = "xterm-kitty"},
    ghostty_term = {TERM = "xterm-ghostty"},
}
local KITTY_ENVIRONMENT <const>: {string: string} = {TERM = "xterm-kitty"}

local saved_environment: {string: string} = {}

local function set_environment(values: {string: string})
    for _, name in ipairs(ENVIRONMENT_NAMES) do
        vim.env[name] = values[name]
    end
end

spec.describe(
    "terminal_capability",
    function()
        spec.before_each(
            function()
                for _, name in ipairs(ENVIRONMENT_NAMES) do
                    saved_environment[name] = vim.env[name]
                end
                vim.o.termguicolors = true
                stub.replace(
                    vim.api, "nvim_list_uis", function(): {any} return FAKE_UIS end
                )
            end
        )

        spec.after_each(function() set_environment(saved_environment) end)

        spec.it(
            "detects kitty graphics terminals",
            function()
                for description, environment in pairs(CAPABLE_ENVIRONMENTS) do
                    set_environment(environment)
                    expect.truthy(
                        terminal_capability.supports_kitty_graphics(), description
                    )
                end
            end
        )

        spec.it(
            "rejects unknown terminals",
            function()
                set_environment(
                    {TERM = "xterm-256color", TERM_PROGRAM = "Apple_Terminal"}
                )
                expect.falsy(terminal_capability.supports_kitty_graphics(), "unknown")
            end
        )

        spec.it(
            "rejects tmux even inside a capable terminal",
            function()
                set_environment({TERM = "xterm-kitty", TMUX = "/tmp/tmux-1000/default"})
                expect.falsy(terminal_capability.supports_kitty_graphics(), "tmux")
            end
        )

        spec.it(
            "requires true colors",
            function()
                set_environment(KITTY_ENVIRONMENT)
                vim.o.termguicolors = false
                expect.falsy(
                    terminal_capability.supports_kitty_graphics(), "no termguicolors"
                )
            end
        )

        spec.it(
            "requires an attached UI",
            function()
                set_environment(KITTY_ENVIRONMENT)
                stub.replace(vim.api, "nvim_list_uis", function(): {any} return {} end)
                expect.falsy(terminal_capability.supports_kitty_graphics(), "headless")
            end
        )
    end
)
