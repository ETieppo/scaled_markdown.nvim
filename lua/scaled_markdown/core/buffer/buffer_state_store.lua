---@class buffer_state_store
local buffer_state_store = {}

---@type table<integer, boolean>
local attached_buffers = {}

---@param buf integer
function buffer_state_store.mark_attached(buf) attached_buffers[buf] = true end

---@param buf integer
function buffer_state_store.mark_detached(buf) attached_buffers[buf] = nil end

---@param buf integer
---@return boolean
function buffer_state_store.is_attached(buf)
  return attached_buffers[buf] == true
end

---@return integer[]
function buffer_state_store.list_attached()
  return vim.tbl_keys(attached_buffers)
end

return buffer_state_store
