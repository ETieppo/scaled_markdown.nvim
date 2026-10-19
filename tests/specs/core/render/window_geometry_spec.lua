local expect = require 'harness.assertions'
local spec = require 'harness.spec'
local buffer_factory = require 'helpers.buffer_factory'
local window_geometry = require 'scaled_markdown.core.render.window_geometry'

local NUMBER_WIDTH = 4
local MINIMUM_WINDOW_WIDTH = 1

spec.describe('window_geometry', function()
  spec.it('has no text offset without gutter columns', function()
    buffer_factory.from_lines { 'a' }
    local win = vim.api.nvim_get_current_win()
    expect.equal(window_geometry.text_offset(win), 0, 'no offset')
    expect.equal(
      window_geometry.text_area_width(win),
      vim.api.nvim_win_get_width(win),
      'full width'
    )
  end)

  spec.it('subtracts the number column from the text area', function()
    buffer_factory.from_lines { 'a' }
    local win = vim.api.nvim_get_current_win()
    vim.wo[win].number = true
    vim.wo[win].numberwidth = NUMBER_WIDTH
    expect.equal(window_geometry.text_offset(win), NUMBER_WIDTH, 'offset')
    expect.equal(
      window_geometry.text_area_width(win),
      vim.api.nvim_win_get_width(win) - NUMBER_WIDTH,
      'reduced width'
    )
  end)

  spec.it('never reports a text area narrower than one column', function()
    buffer_factory.from_lines { 'a' }
    vim.cmd.vsplit()
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_config(win, { width = MINIMUM_WINDOW_WIDTH })
    vim.wo[win].number = true
    expect.at_least(window_geometry.text_area_width(win), 1, 'minimum width')
  end)
end)
