local buffer_factory = require 'helpers.buffer_factory'
local expect = require 'harness.assertions'
local reveal_range = require 'scaled_markdown.core.render.reveal_range'
local spec = require 'harness.spec'

---@type string[]
local LINES = { 'a', 'b', 'c', 'd', 'e' }
local CURSOR_LINE = 3
local SELECTION_START_LINE = 2
local SELECT_THREE_LINES = 'normal! Vjj'
local LEAVE_VISUAL_MODE = 'normal! \27'
---@type RevealProps
local ALL_REVEAL = {
  cursor_line = true,
  visual_selection = true,
}
---@type RevealProps
local NO_REVEAL = {
  cursor_line = false,
  visual_selection = false,
}
---@type RevealProps
local CURSOR_ONLY_REVEAL = {
  cursor_line = true,
  visual_selection = false,
}

---@param reveal_config RevealProps
---@return table<integer, boolean>
local function collect_while_selecting(reveal_config)
  buffer_factory.from_lines(LINES)
  vim.api.nvim_win_set_cursor(0, { SELECTION_START_LINE, 0 })
  vim.cmd(SELECT_THREE_LINES)
  local revealed = reveal_range.collect_revealed_rows(
    vim.api.nvim_get_current_win(),
    reveal_config
  )
  vim.cmd(LEAVE_VISUAL_MODE)
  return revealed
end

spec.describe('reveal_range', function()
  spec.it('reveals the cursor row', function()
    buffer_factory.from_lines(LINES)
    vim.api.nvim_win_set_cursor(0, { CURSOR_LINE, 0 })
    expect.deep_equal(
      reveal_range.collect_revealed_rows(
        vim.api.nvim_get_current_win(),
        ALL_REVEAL
      ),
      { [CURSOR_LINE - 1] = true },
      'cursor row'
    )
  end)

  spec.it('reveals nothing when cursor reveal is disabled', function()
    buffer_factory.from_lines(LINES)
    expect.deep_equal(
      reveal_range.collect_revealed_rows(
        vim.api.nvim_get_current_win(),
        NO_REVEAL
      ),
      {},
      'nothing revealed'
    )
  end)

  spec.it(
    'reveals the whole visual selection',
    function()
      expect.deep_equal(
        collect_while_selecting(ALL_REVEAL),
        { [1] = true, [2] = true, [3] = true },
        'selection'
      )
    end
  )

  spec.it(
    'ignores the visual selection when disabled',
    function()
      expect.deep_equal(
        collect_while_selecting(CURSOR_ONLY_REVEAL),
        { [3] = true },
        'cursor only'
      )
    end
  )
end)
