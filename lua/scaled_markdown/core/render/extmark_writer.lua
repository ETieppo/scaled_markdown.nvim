local CORE_CONSTANTS = require 'scaled_markdown.core.constants'

---@type [string, string][]
local BLANK_VIRTUAL_LINE = {}

---@class extmark_writer
local extmark_writer = {}

---@param extmark_options vim.api.keyset.set_extmark
---@return vim.api.keyset.set_extmark?
local function build_height_placeholder(extmark_options)
  if not extmark_options.virt_lines or #extmark_options.virt_lines == 0 then
    return nil
  end
  ---@type [string, string][][]
  local blank_lines = {}
  for line_index = 1, #extmark_options.virt_lines do
    blank_lines[line_index] = BLANK_VIRTUAL_LINE
  end
  return {
    virt_lines = blank_lines,
    virt_lines_above = extmark_options.virt_lines_above,
  }
end

---@param extmark_options vim.api.keyset.set_extmark
---@param text_offset integer
---@return vim.api.keyset.set_extmark
local function anchor_virtual_lines_to_left_column(extmark_options, text_offset)
  if not extmark_options.virt_lines then return extmark_options end
  ---@type [string, string]
  local gutter_chunk =
    { string.rep(' ', text_offset), CORE_CONSTANTS.PADDING_HIGHLIGHT }
  ---@type [string, string][][]
  local anchored_lines = {}
  for line_index, line_chunks in ipairs(extmark_options.virt_lines) do
    anchored_lines[line_index] = { gutter_chunk, unpack(line_chunks) }
  end
  return vim.tbl_extend('force', extmark_options, {
    virt_lines = anchored_lines,
    virt_lines_leftcol = true,
  })
end

---@param buf integer
---@param namespace_id integer
---@param revealed_rows table<integer, boolean>
---@param text_offset integer
---@return ExtmarkWriterProps
function extmark_writer.new(buf, namespace_id, revealed_rows, text_offset)
  ---@type ExtmarkWriterProps
  local writer = {}

  ---@param row integer
  ---@param col integer
  ---@param extmark_options vim.api.keyset.set_extmark
  ---@return integer?
  function writer.set_extmark(row, col, extmark_options)
    if revealed_rows[row] then
      local placeholder_options = build_height_placeholder(extmark_options)
      if not placeholder_options then return nil end
      extmark_options = placeholder_options
    end
    local options = vim.tbl_extend(
      'force',
      { strict = false },
      anchor_virtual_lines_to_left_column(extmark_options, text_offset)
    )
    local ok, extmark_id =
      pcall(vim.api.nvim_buf_set_extmark, buf, namespace_id, row, col, options)
    return ok and extmark_id or nil
  end

  return writer
end

return extmark_writer
