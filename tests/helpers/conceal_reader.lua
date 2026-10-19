local extmark_reader = require 'helpers.extmark_reader'

local HIDDEN_CONCEAL = ''

---@class conceal_reader
local conceal_reader = {}

---@param buf integer
---@param row integer
---@return string
function conceal_reader.visible_text(buf, row)
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
  ---@type table<integer, boolean>
  local hidden_columns = {}
  for _, entry in ipairs(extmark_reader.on_row(buf, row)) do
    if entry.details.conceal == HIDDEN_CONCEAL then
      for column = entry.col + 1, entry.details.end_col do
        hidden_columns[column] = true
      end
    end
  end
  ---@type string[]
  local visible = {}
  for column = 1, #line do
    if not hidden_columns[column] then
      visible[#visible + 1] = line:sub(column, column)
    end
  end
  return table.concat(visible)
end

---@param buf integer
---@param row integer
---@return string[]
function conceal_reader.concealed_texts(buf, row)
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
  ---@type string[]
  local texts = {}
  for _, entry in ipairs(extmark_reader.on_row(buf, row)) do
    if entry.details.conceal == HIDDEN_CONCEAL then
      texts[#texts + 1] = line:sub(entry.col + 1, entry.details.end_col)
    end
  end
  table.sort(texts)
  return texts
end

---@param buf integer
---@param row integer
---@param highlight_group string
---@return string?
function conceal_reader.highlighted_text(buf, row, highlight_group)
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
  for _, entry in ipairs(extmark_reader.on_row(buf, row)) do
    if entry.details.hl_group == highlight_group then
      return line:sub(entry.col + 1, entry.details.end_col)
    end
  end
  return nil
end

return conceal_reader
