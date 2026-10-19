local expect = require 'harness.assertions'
local spec = require 'harness.spec'
local stub = require 'harness.stub'
local terminal_capability =
  require 'scaled_markdown.core.terminal.terminal_capability'
local plugin_session = require 'helpers.plugin_session'
local tmux_client = require 'scaled_markdown.core.terminal.tmux_client'

---@type string[]
local ENVIRONMENT_NAMES = {
  'TMUX',
  'TERM',
  'TERM_PROGRAM',
  'KITTY_WINDOW_ID',
}
---@type any[]
local FAKE_UIS = { { chan = 1 } }
---@type table<string, table<string, string>>
local CAPABLE_ENVIRONMENTS = {
  kitty_window = { KITTY_WINDOW_ID = '1' },
  ghostty_program = { TERM_PROGRAM = 'ghostty' },
  wezterm_program = { TERM_PROGRAM = 'WezTerm' },
  kitty_term = { TERM = 'xterm-kitty' },
  ghostty_term = { TERM = 'xterm-ghostty' },
}
---@type table<string, string>
local KITTY_ENVIRONMENT = { TERM = 'xterm-kitty' }

---@type table<string, string>
local TMUX_ENVIRONMENT =
  { TERM = 'tmux-256color', TMUX = '/tmp/tmux-1000/default,1,0' }
---@type TmuxClientProps
local GHOSTTY_CLIENT = {
  term_name = 'xterm-ghostty',
  term_type = '',
  features = { RGB = true },
  passthrough = 'off',
}

---@type table<string, string>
local saved_environment = {}

---@param client_props? TmuxClientProps
---@return boolean[]
local function stub_tmux_client(client_props)
  ---@type boolean[]
  local passthrough_requests = {}
  stub.replace(tmux_client, 'probe', function() return client_props end)
  stub.replace(
    tmux_client,
    'ensure_passthrough',
    ---@param may_change_option boolean
    function(may_change_option)
      passthrough_requests[#passthrough_requests + 1] = may_change_option
      return may_change_option
    end
  )
  return passthrough_requests
end

---@param values table<string, string>
local function set_environment(values)
  for _, name in ipairs(ENVIRONMENT_NAMES) do
    vim.env[name] = values[name]
  end
end

spec.describe('terminal_capability', function()
  spec.before_each(function()
    for _, name in ipairs(ENVIRONMENT_NAMES) do
      saved_environment[name] = vim.env[name]
    end
    vim.o.termguicolors = true
    stub.replace(vim.api, 'nvim_list_uis', function() return FAKE_UIS end)
  end)

  spec.after_each(function() set_environment(saved_environment) end)

  spec.it('detects kitty graphics terminals', function()
    for description, environment in pairs(CAPABLE_ENVIRONMENTS) do
      set_environment(environment)
      expect.truthy(terminal_capability.supports_kitty_graphics(), description)
    end
  end)

  spec.it('rejects unknown terminals', function()
    set_environment { TERM = 'xterm-256color', TERM_PROGRAM = 'Apple_Terminal' }
    expect.falsy(terminal_capability.supports_kitty_graphics(), 'unknown')
  end)

  spec.it('accepts tmux attached from a capable terminal', function()
    plugin_session.start { renderer = 'plain' }
    set_environment(TMUX_ENVIRONMENT)
    local passthrough_requests = stub_tmux_client(GHOSTTY_CLIENT)
    local capability = terminal_capability.detect()
    expect.truthy(capability.supports_kitty_graphics, 'tmux supported')
    expect.truthy(capability.is_inside_tmux, 'inside tmux')
    expect.deep_equal(passthrough_requests, { true }, 'passthrough enabled')
  end)

  spec.it('recognizes the client terminal by its reported type', function()
    plugin_session.start { renderer = 'plain' }
    set_environment(TMUX_ENVIRONMENT)
    stub_tmux_client {
      term_name = 'xterm-256color',
      term_type = 'WezTerm 20240203',
      features = { RGB = true },
      passthrough = 'all',
    }
    expect.truthy(terminal_capability.supports_kitty_graphics(), 'wezterm')
  end)

  spec.it('rejects tmux clients from unknown terminals', function()
    plugin_session.start { renderer = 'plain' }
    set_environment(TMUX_ENVIRONMENT)
    stub_tmux_client {
      term_name = 'xterm-256color',
      term_type = 'xterm(390)',
      features = { RGB = true },
      passthrough = 'all',
    }
    expect.falsy(
      terminal_capability.supports_kitty_graphics(),
      'unknown client'
    )
  end)

  spec.it('rejects tmux clients without true color', function()
    plugin_session.start { renderer = 'plain' }
    set_environment(TMUX_ENVIRONMENT)
    stub_tmux_client {
      term_name = 'xterm-ghostty',
      term_type = '',
      features = {},
      passthrough = 'all',
    }
    local capability = terminal_capability.detect()
    expect.falsy(capability.supports_kitty_graphics, 'no RGB')
    expect.matches(capability.unsupported_reason, 'RGB', 'reason')
  end)

  spec.it('rejects tmux when passthrough may not be enabled', function()
    plugin_session.start {
      renderer = 'plain',
      terminal = { allow_tmux_passthrough = false },
    }
    set_environment(TMUX_ENVIRONMENT)
    local passthrough_requests = stub_tmux_client(GHOSTTY_CLIENT)
    expect.falsy(
      terminal_capability.supports_kitty_graphics(),
      'no passthrough'
    )
    expect.deep_equal(passthrough_requests, { false }, 'option left alone')
  end)

  spec.it('rejects tmux when the client cannot be queried', function()
    plugin_session.start { renderer = 'plain' }
    set_environment(TMUX_ENVIRONMENT)
    stub_tmux_client(nil)
    expect.falsy(terminal_capability.supports_kitty_graphics(), 'no client')
  end)

  spec.it('requires true colors', function()
    set_environment(KITTY_ENVIRONMENT)
    vim.o.termguicolors = false
    expect.falsy(
      terminal_capability.supports_kitty_graphics(),
      'no termguicolors'
    )
  end)

  spec.it('requires an attached UI', function()
    set_environment(KITTY_ENVIRONMENT)
    stub.replace(vim.api, 'nvim_list_uis', function() return {} end)
    expect.falsy(terminal_capability.supports_kitty_graphics(), 'headless')
  end)
end)
