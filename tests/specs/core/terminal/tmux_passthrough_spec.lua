local expect = require 'harness.assertions'
local spec = require 'harness.spec'
local tmux_passthrough =
  require 'scaled_markdown.core.terminal.tmux_passthrough'

spec.describe('tmux_passthrough', function()
  spec.it(
    'wraps a sequence in a tmux DCS passthrough',
    function()
      expect.equal(
        tmux_passthrough.wrap '\27_Ga=d\27\\',
        '\27Ptmux;\27\27_Ga=d\27\27\\\27\\',
        'wrapped'
      )
    end
  )

  spec.it(
    'keeps sequences without escapes unchanged inside',
    function()
      expect.equal(tmux_passthrough.wrap 'abc', '\27Ptmux;abc\27\\', 'plain')
    end
  )
end)
