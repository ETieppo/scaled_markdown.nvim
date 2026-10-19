local render_pipeline = require 'scaled_markdown.core.render.render_pipeline'

---@class extmark_reader
local extmark_reader = {}

---@param extmark vim.api.keyset.get_extmark_item
---@return ExtmarkEntryProps
local function to_entry(extmark)
  return { row = extmark[2], col = extmark[3], details = extmark[4] }
end

---@param chunks [string, string][]
---@return string
local function join_chunks(chunks)
  ---@type string[]
  local parts = {}
  for _, chunk in ipairs(chunks or {}) do
    parts[#parts + 1] = chunk[1]
  end
  return table.concat(parts)
end

---@param buf integer
---@return ExtmarkEntryProps[]
function extmark_reader.list(buf)
  ---@type ExtmarkEntryProps[]
  local entries = {}
  for _, extmark in
    ipairs(
      vim.api.nvim_buf_get_extmarks(
        buf,
        render_pipeline.namespace_id(),
        0,
        -1,
        { details = true }
      )
    )
  do
    entries[#entries + 1] = to_entry(extmark)
  end
  return entries
end

---@param buf integer
---@param row integer
---@return ExtmarkEntryProps[]
function extmark_reader.on_row(buf, row)
  return vim.tbl_filter(
    ---@param entry ExtmarkEntryProps
    ---@return boolean
    function(entry) return entry.row == row end,
    extmark_reader.list(buf)
  )
end

---@param buf integer
---@param predicate ExtmarkPredicateProps
---@return ExtmarkEntryProps[]
function extmark_reader.find_all(buf, predicate)
  return vim.tbl_filter(
    ---@param entry ExtmarkEntryProps
    ---@return boolean
    function(entry) return predicate(entry.details, entry) end,
    extmark_reader.list(buf)
  )
end

---@param buf integer
---@param predicate ExtmarkPredicateProps
---@return ExtmarkEntryProps
function extmark_reader.find(buf, predicate)
  return extmark_reader.find_all(buf, predicate)[1]
end

---@param details vim.api.keyset.set_extmark
---@return string
function extmark_reader.virt_text_string(details)
  return join_chunks(details.virt_text)
end

---@param virt_line [string, string][]
---@return string
function extmark_reader.virt_line_string(virt_line)
  return join_chunks(virt_line)
end

return extmark_reader
