local FIXTURES_DIRECTORY = 'tests/fixtures'
local FIXTURE_PATH_FORMAT = '%s/%s'
local MARKDOWN_FILETYPE = 'markdown'
local SCRATCH_BUFTYPE = 'nofile'

---@class buffer_factory
local buffer_factory = {}

---@param lines string[]
---@return integer
function buffer_factory.from_lines(lines)
  vim.cmd.enew()
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype = SCRATCH_BUFTYPE
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = MARKDOWN_FILETYPE
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  return buf
end

---@param fixture_name string
---@return integer
function buffer_factory.from_fixture(fixture_name)
  vim.cmd.edit(FIXTURE_PATH_FORMAT:format(FIXTURES_DIRECTORY, fixture_name))
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].filetype = MARKDOWN_FILETYPE
  return buf
end

---@param buf integer
function buffer_factory.move_cursor_away(buf)
  vim.api.nvim_win_set_cursor(0, { vim.api.nvim_buf_line_count(buf), 0 })
end

return buffer_factory
