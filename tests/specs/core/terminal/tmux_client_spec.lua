local expect = require 'harness.assertions'
local spec = require 'harness.spec'
local stub = require 'harness.stub'
local tmux_client = require 'scaled_markdown.core.terminal.tmux_client'

local PANE_ID = '%3'
local PROBE_OUTPUT =
  'xterm-ghostty\tghostty 1.2.0\tbpaste,clipboard,RGB,title\t10\t21\toff\t1\n'

---@param outputs_by_subcommand table<string, string?>
---@return string[][]
local function stub_tmux(outputs_by_subcommand)
  ---@type string[][]
  local commands = {}
  stub.replace(vim.fn, 'executable', function() return 1 end)
  stub.replace(
    vim,
    'system',
    ---@param command string[]
    function(command)
      commands[#commands + 1] = command
      local output = outputs_by_subcommand[command[2]]
      return {
        wait = function()
          return { code = output and 0 or 1, stdout = output or '' }
        end,
      }
    end
  )
  return commands
end

spec.describe('tmux_client', function()
  ---@type table<string, string?>
  local saved_environment

  spec.before_each(function()
    saved_environment = { TMUX = vim.env.TMUX, TMUX_PANE = vim.env.TMUX_PANE }
    vim.env.TMUX = '/tmp/tmux-1000/default,1,0'
    vim.env.TMUX_PANE = PANE_ID
    tmux_client.reset()
  end)

  spec.after_each(function()
    stub_tmux {}
    tmux_client.restore_passthrough()
    stub.restore_all()
    vim.env.TMUX = saved_environment.TMUX
    vim.env.TMUX_PANE = saved_environment.TMUX_PANE
    tmux_client.reset()
  end)

  spec.it('reads the client terminal, features and cell size', function()
    stub_tmux { ['display-message'] = PROBE_OUTPUT }
    expect.deep_equal(tmux_client.probe(), {
      term_name = 'xterm-ghostty',
      term_type = 'ghostty 1.2.0',
      features = { bpaste = true, clipboard = true, RGB = true, title = true },
      cell_width = 10,
      cell_height = 21,
      passthrough = 'off',
      has_sixel_support = true,
    }, 'client props')
  end)

  spec.it('targets the pane running neovim', function()
    local commands = stub_tmux { ['display-message'] = PROBE_OUTPUT }
    tmux_client.probe()
    expect.equal(commands[1][3], '-t', 'target flag')
    expect.equal(commands[1][4], PANE_ID, 'pane id')
  end)

  spec.it('queries tmux only once until reset', function()
    local commands = stub_tmux { ['display-message'] = PROBE_OUTPUT }
    tmux_client.probe()
    tmux_client.probe()
    expect.equal(#commands, 1, 'cached')
    tmux_client.reset()
    tmux_client.probe()
    expect.equal(#commands, 2, 'probed again')
  end)

  spec.it('treats unknown cell sizes as missing', function()
    stub_tmux {
      ['display-message'] = 'xterm-kitty\t\tRGB\t0\t0\tall\t\n',
    }
    local client_props = tmux_client.probe()
    ---@cast client_props -nil
    expect.is_nil(client_props.cell_width, 'width')
    expect.is_nil(client_props.cell_height, 'height')
  end)

  spec.it('returns nothing outside tmux', function()
    vim.env.TMUX = nil
    local commands = stub_tmux { ['display-message'] = PROBE_OUTPUT }
    expect.is_nil(tmux_client.probe(), 'no probe')
    expect.equal(#commands, 0, 'no process')
  end)

  spec.it('enables passthrough on the pane when allowed', function()
    local commands = stub_tmux {
      ['display-message'] = PROBE_OUTPUT,
      ['show-options'] = '\n',
      ['set-option'] = '',
    }
    expect.truthy(tmux_client.ensure_passthrough(true), 'enabled')
    expect.deep_equal(
      commands[3],
      { 'tmux', 'set-option', '-t', PANE_ID, '-p', 'allow-passthrough', 'all' },
      'pane scoped option'
    )
    expect.truthy(tmux_client.ensure_passthrough(true), 'still enabled')
    expect.equal(#commands, 3, 'option set once')
  end)

  spec.it('falls back to on when tmux rejects all', function()
    local commands = stub_tmux {
      ['display-message'] = PROBE_OUTPUT,
      ['show-options'] = '\n',
    }
    stub.replace(
      vim,
      'system',
      ---@param command string[]
      function(command)
        commands[#commands + 1] = command
        local is_rejected = command[2] == 'set-option'
          and command[#command] == 'all'
        local output = ({
          ['display-message'] = PROBE_OUTPUT,
          ['show-options'] = '\n',
          ['set-option'] = '',
        })[command[2]]
        return {
          wait = function()
            return { code = is_rejected and 1 or 0, stdout = output or '' }
          end,
        }
      end
    )
    expect.truthy(tmux_client.ensure_passthrough(true), 'enabled with on')
    expect.equal(commands[#commands][#commands[#commands]], 'on', 'on value')
  end)

  spec.it('tries to change passthrough only once until reset', function()
    local commands = stub_tmux {
      ['display-message'] = PROBE_OUTPUT,
      ['show-options'] = '\n',
    }
    expect.falsy(tmux_client.ensure_passthrough(true), 'rejected')
    local command_count = #commands
    expect.falsy(tmux_client.ensure_passthrough(true), 'still rejected')
    expect.equal(#commands, command_count, 'no retry')
  end)

  spec.it('unsets an inherited passthrough option on restore', function()
    local commands = stub_tmux {
      ['display-message'] = PROBE_OUTPUT,
      ['show-options'] = '\n',
      ['set-option'] = '',
    }
    tmux_client.ensure_passthrough(true)
    tmux_client.restore_passthrough()
    expect.deep_equal(
      commands[#commands],
      { 'tmux', 'set-option', '-t', PANE_ID, '-p', '-u', 'allow-passthrough' },
      'unset'
    )
  end)

  spec.it('restores a pane level passthrough value', function()
    local commands = stub_tmux {
      ['display-message'] = PROBE_OUTPUT,
      ['show-options'] = 'off\n',
      ['set-option'] = '',
    }
    tmux_client.ensure_passthrough(true)
    tmux_client.restore_passthrough()
    expect.deep_equal(
      commands[#commands],
      { 'tmux', 'set-option', '-t', PANE_ID, '-p', 'allow-passthrough', 'off' },
      'restored'
    )
  end)

  spec.it('restores nothing when passthrough was never changed', function()
    local commands = stub_tmux { ['display-message'] = PROBE_OUTPUT }
    tmux_client.restore_passthrough()
    expect.equal(#commands, 0, 'no command')
  end)

  spec.it('leaves passthrough off when not allowed to change it', function()
    local commands = stub_tmux { ['display-message'] = PROBE_OUTPUT }
    expect.falsy(tmux_client.ensure_passthrough(false), 'disabled')
    expect.equal(#commands, 1, 'option untouched')
  end)

  spec.it('accepts passthrough the user already turned on', function()
    stub_tmux {
      ['display-message'] = PROBE_OUTPUT:gsub('\toff\t', '\ton\t'),
    }
    expect.truthy(tmux_client.ensure_passthrough(false), 'on is enough')
  end)
end)
