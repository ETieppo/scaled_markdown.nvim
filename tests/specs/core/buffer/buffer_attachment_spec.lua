local expect = require 'harness.assertions'
local spec = require 'harness.spec'
local buffer_factory = require 'helpers.buffer_factory'
local extmark_reader = require 'helpers.extmark_reader'
local plugin_session = require 'helpers.plugin_session'
local buffer_attachment =
  require 'scaled_markdown.core.buffer.buffer_attachment'

---@type string[]
local LINES = { '# Title', '', 'Some **strong** text' }
---@type string[]
local APPENDED_LINES = { '', '## Another' }
local BUFFER_AUGROUP_PREFIX = 'ScaledMarkdownBuffer'
local ORIGINAL_CONCEALLEVEL = 0
local ATTACHED_CONCEALLEVEL = 2
local INVALID_BUFFER = 99999
local RERENDER_WAIT_MS = 1000

---@param buf integer
---@return boolean
local function has_buffer_augroup(buf)
  return (
    pcall(vim.api.nvim_get_autocmds, { group = BUFFER_AUGROUP_PREFIX .. buf })
  )
end

spec.describe('buffer_attachment', function()
  spec.before_each(
    function()
      plugin_session.start { renderer = 'plain', file_types = { 'none' } }
    end
  )

  spec.it(
    'renders, registers autocmds and sets window options on attach',
    function()
      local buf = buffer_factory.from_lines(LINES)
      vim.wo.conceallevel = ORIGINAL_CONCEALLEVEL
      buffer_attachment.attach(buf)
      expect.truthy(buffer_attachment.is_attached(buf), 'attached')
      expect.at_least(#extmark_reader.list(buf), 1, 'rendered')
      expect.truthy(has_buffer_augroup(buf), 'buffer augroup')
      expect.equal(vim.wo.conceallevel, ATTACHED_CONCEALLEVEL, 'conceallevel')
    end
  )

  spec.it('clears, unregisters and restores on detach', function()
    local buf = buffer_factory.from_lines(LINES)
    vim.wo.conceallevel = ORIGINAL_CONCEALLEVEL
    buffer_attachment.attach(buf)
    buffer_attachment.detach(buf)
    expect.falsy(buffer_attachment.is_attached(buf), 'detached')
    expect.equal(#extmark_reader.list(buf), 0, 'cleared')
    expect.falsy(has_buffer_augroup(buf), 'augroup removed')
    expect.equal(vim.wo.conceallevel, ORIGINAL_CONCEALLEVEL, 'restored')
  end)

  spec.it('treats buffer 0 and nil as the current buffer', function()
    local buf = buffer_factory.from_lines(LINES)
    buffer_attachment.attach(0)
    expect.truthy(buffer_attachment.is_attached(buf), 'attached via 0')
    buffer_attachment.detach()
    expect.falsy(buffer_attachment.is_attached(buf), 'detached via nil')
  end)

  spec.it('toggles between attached and detached', function()
    local buf = buffer_factory.from_lines(LINES)
    buffer_attachment.toggle(buf)
    expect.truthy(buffer_attachment.is_attached(buf), 'toggled on')
    buffer_attachment.toggle(buf)
    expect.falsy(buffer_attachment.is_attached(buf), 'toggled off')
  end)

  spec.it('detaches automatically when the buffer is wiped', function()
    local buf = buffer_factory.from_lines(LINES)
    buffer_attachment.attach(buf)
    vim.cmd.enew()
    vim.api.nvim_buf_delete(buf, { force = true })
    expect.falsy(buffer_attachment.is_attached(buf), 'detached on wipe')
  end)

  spec.it('ignores invalid buffers', function()
    expect.succeeds(
      function() buffer_attachment.attach(INVALID_BUFFER) end,
      'invalid buffer'
    )
    expect.falsy(buffer_attachment.is_attached(INVALID_BUFFER), 'not attached')
  end)

  spec.it('re-renders on text change after the debounce', function()
    local buf = buffer_factory.from_lines(LINES)
    buffer_attachment.attach(buf)
    local before_count = #extmark_reader.list(buf)
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, APPENDED_LINES)
    vim.api.nvim_exec_autocmds('TextChanged', { buffer = buf })
    expect.truthy(
      vim.wait(
        RERENDER_WAIT_MS,
        ---@return boolean
        function() return #extmark_reader.list(buf) > before_count end
      ),
      'new heading rendered'
    )
  end)
end)
