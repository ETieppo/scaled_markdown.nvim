local expect = require 'harness.assertions'
local plugin_session = require 'helpers.plugin_session'
local spec = require 'harness.spec'
local stub = require 'harness.stub'
local terminal_capability =
  require 'scaled_markdown.core.terminal.terminal_capability'
local terminal_query = require 'scaled_markdown.core.terminal.terminal_query'
local tmux_client = require 'scaled_markdown.core.terminal.tmux_client'

local KITTY_PLACEHOLDER = 'kitty_placeholder'
local SIXEL = 'sixel'
local NONE = 'none'
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
local PLACEHOLDER_ENVIRONMENTS = {
  kitty_window = { KITTY_WINDOW_ID = '1' },
  ghostty_program = { TERM_PROGRAM = 'ghostty' },
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
local SIXEL_ATTRIBUTES_RESPONSE = '\27[?62;4;22c'
local PLAIN_ATTRIBUTES_RESPONSE = '\27[?62;22c'

---@type table<string, string>
local saved_environment = {}

---@param values table<string, string>
local function set_environment(values)
  for _, name in ipairs(ENVIRONMENT_NAMES) do
    vim.env[name] = values[name]
  end
end

---@param version_text string
local function report_version(version_text)
  terminal_query.handle_response('\27P>|' .. version_text .. '\27\\')
end

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

spec.describe('terminal_capability', function()
  spec.before_each(function()
    for _, name in ipairs(ENVIRONMENT_NAMES) do
      saved_environment[name] = vim.env[name]
    end
    plugin_session.start { renderer = 'plain' }
    terminal_query.reset()
    vim.o.termguicolors = true
    stub.replace(vim.api, 'nvim_list_uis', function() return FAKE_UIS end)
    set_environment {}
  end)

  spec.after_each(function()
    set_environment(saved_environment)
    terminal_query.reset()
  end)

  spec.it('uses placeholders in kitty and ghostty environments', function()
    for description, environment in pairs(PLACEHOLDER_ENVIRONMENTS) do
      set_environment(environment)
      expect.equal(
        terminal_capability.protocol(),
        KITTY_PLACEHOLDER,
        description
      )
    end
  end)

  spec.it('never uses placeholders in wezterm', function()
    set_environment { TERM_PROGRAM = 'WezTerm', TERM = 'xterm-256color' }
    expect.equal(terminal_capability.protocol(), NONE, 'no placeholders')
    terminal_query.handle_response(SIXEL_ATTRIBUTES_RESPONSE)
    expect.equal(terminal_capability.protocol(), SIXEL, 'sixel instead')
  end)

  spec.it('uses sixel when the terminal reports it', function()
    set_environment { TERM = 'foot' }
    terminal_query.handle_response(SIXEL_ATTRIBUTES_RESPONSE)
    expect.equal(terminal_capability.protocol(), SIXEL, 'sixel')
  end)

  spec.it('trusts the reported terminal name over the environment', function()
    set_environment(KITTY_ENVIRONMENT)
    report_version 'WezTerm 20240203-110809-5046fc22'
    terminal_query.handle_response(SIXEL_ATTRIBUTES_RESPONSE)
    expect.equal(terminal_capability.protocol(), SIXEL, 'reported wezterm')
    report_version 'ghostty 1.1.3'
    expect.equal(terminal_capability.protocol(), KITTY_PLACEHOLDER, 'ghostty')
  end)

  spec.it('requires kitty 0.28 for placeholders', function()
    report_version 'kitty(0.27.1)'
    expect.equal(terminal_capability.protocol(), NONE, 'old kitty')
    report_version 'kitty(0.28.0)'
    expect.equal(terminal_capability.protocol(), KITTY_PLACEHOLDER, 'new kitty')
  end)

  spec.it('rejects terminals without any graphics support', function()
    set_environment { TERM = 'xterm-256color', TERM_PROGRAM = 'Apple_Terminal' }
    terminal_query.handle_response(PLAIN_ATTRIBUTES_RESPONSE)
    local capability = terminal_capability.detect()
    expect.equal(capability.protocol, NONE, 'unknown')
    expect.truthy(capability.unsupported_reason, 'reason')
  end)

  spec.it('honors an explicit protocol', function()
    plugin_session.start {
      renderer = 'plain',
      terminal = { graphics_protocol = SIXEL },
    }
    set_environment(KITTY_ENVIRONMENT)
    expect.equal(terminal_capability.protocol(), SIXEL, 'forced sixel')
  end)

  spec.it('disables graphics when the protocol is none', function()
    plugin_session.start {
      renderer = 'plain',
      terminal = { graphics_protocol = NONE },
    }
    set_environment(KITTY_ENVIRONMENT)
    expect.equal(terminal_capability.protocol(), NONE, 'disabled')
  end)

  spec.it('accepts tmux attached from a placeholder terminal', function()
    set_environment(TMUX_ENVIRONMENT)
    local passthrough_requests = stub_tmux_client(GHOSTTY_CLIENT)
    local capability = terminal_capability.detect()
    expect.equal(capability.protocol, KITTY_PLACEHOLDER, 'tmux supported')
    expect.truthy(capability.is_inside_tmux, 'inside tmux')
    expect.deep_equal(passthrough_requests, { true }, 'passthrough enabled')
  end)

  spec.it('rejects tmux clients from wezterm and unknown terminals', function()
    set_environment(TMUX_ENVIRONMENT)
    stub_tmux_client {
      term_name = 'xterm-256color',
      term_type = 'WezTerm 20240203',
      features = { RGB = true },
      passthrough = 'all',
    }
    terminal_query.handle_response(SIXEL_ATTRIBUTES_RESPONSE)
    expect.equal(terminal_capability.protocol(), NONE, 'no sixel in tmux')
  end)

  spec.it('rejects tmux clients without true color', function()
    set_environment(TMUX_ENVIRONMENT)
    stub_tmux_client {
      term_name = 'xterm-ghostty',
      term_type = '',
      features = {},
      passthrough = 'all',
    }
    local capability = terminal_capability.detect()
    expect.equal(capability.protocol, NONE, 'no RGB')
    expect.matches(capability.unsupported_reason, 'RGB', 'reason')
  end)

  spec.it('rejects tmux when passthrough may not be enabled', function()
    plugin_session.start {
      renderer = 'plain',
      terminal = { allow_tmux_passthrough = false },
    }
    set_environment(TMUX_ENVIRONMENT)
    local passthrough_requests = stub_tmux_client(GHOSTTY_CLIENT)
    expect.equal(terminal_capability.protocol(), NONE, 'no passthrough')
    expect.deep_equal(passthrough_requests, { false }, 'option left alone')
  end)

  spec.it('rejects tmux when the client cannot be queried', function()
    set_environment(TMUX_ENVIRONMENT)
    stub_tmux_client(nil)
    expect.equal(terminal_capability.protocol(), NONE, 'no client')
  end)

  spec.it('requires true colors', function()
    set_environment(KITTY_ENVIRONMENT)
    vim.o.termguicolors = false
    expect.equal(terminal_capability.protocol(), NONE, 'no termguicolors')
  end)

  spec.it('requires an attached UI', function()
    set_environment(KITTY_ENVIRONMENT)
    stub.replace(vim.api, 'nvim_list_uis', function() return {} end)
    expect.equal(terminal_capability.protocol(), NONE, 'headless')
  end)
end)
