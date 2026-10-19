local expect = require 'harness.assertions'
local notify_capture = require 'harness.notify_capture'
local spec = require 'harness.spec'
local buffer_factory = require 'helpers.buffer_factory'
local plugin_session = require 'helpers.plugin_session'
local buffer_attachment =
  require 'scaled_markdown.core.buffer.buffer_attachment'
local config_store = require 'scaled_markdown.core.config.config_store'

local COMMAND_NAME = 'ScaledMarkdown'
local CMDLINE_COMPLETION = 'cmdline'
---@type string[]
local SUBCOMMANDS = {
  'disable',
  'enable',
  'refresh',
  'renderer',
  'toggle',
}
---@type string[]
local RENDERERS = {
  'figlet',
  'graphics',
  'plain',
  'toilet',
  'typeface',
}

---@param arguments string
---@return string[]
local function complete(arguments)
  return vim.fn.getcompletion(
    COMMAND_NAME .. ' ' .. arguments,
    CMDLINE_COMPLETION
  )
end

---@param arguments string
local function run(arguments) vim.cmd(COMMAND_NAME .. ' ' .. arguments) end

spec.describe('user_command', function()
  spec.before_each(
    function()
      plugin_session.start { renderer = 'plain', file_types = { 'none' } }
    end
  )

  spec.it(
    'registers the command',
    function()
      expect.truthy(vim.api.nvim_get_commands({})[COMMAND_NAME], 'registered')
    end
  )

  spec.it('completes subcommands sorted and filtered by prefix', function()
    expect.deep_equal(complete '', SUBCOMMANDS, 'all')
    expect.deep_equal(complete 're', { 'refresh', 'renderer' }, 're')
  end)

  spec.it('completes renderer names', function()
    local renderers = complete 'renderer '
    table.sort(renderers)
    expect.deep_equal(renderers, RENDERERS, 'renderers')
    expect.deep_equal(complete 'renderer ty', { 'typeface' }, 'ty')
  end)

  spec.it('enables, toggles and disables the current buffer', function()
    local buf = buffer_factory.from_lines { '# Title' }
    run 'enable'
    expect.truthy(buffer_attachment.is_attached(buf), 'enabled')
    run 'toggle'
    expect.falsy(buffer_attachment.is_attached(buf), 'toggled off')
    run 'toggle'
    run 'disable'
    expect.falsy(buffer_attachment.is_attached(buf), 'disabled')
  end)

  spec.it('switches the renderer', function()
    run 'renderer toilet'
    expect.equal(config_store.get().renderer, 'toilet', 'renderer switched')
  end)

  spec.it('reports unknown renderers without changing the config', function()
    run 'renderer nope'
    local errors = notify_capture.take_errors()
    expect.equal(#errors, 1, 'one error')
    expect.matches(errors[1], 'unknown renderer: nope', 'error message')
    expect.equal(config_store.get().renderer, 'plain', 'renderer unchanged')
  end)

  spec.it('reports unknown subcommands', function()
    run 'nope'
    local errors = notify_capture.take_errors()
    expect.equal(#errors, 1, 'one error')
    expect.matches(errors[1], 'unknown subcommand: nope', 'error message')
  end)
end)
