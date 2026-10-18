local buffer_state_store = {}


local attached_buffers = {}

function buffer_state_store.mark_attached(
   buf)
   attached_buffers[buf] = true end

function buffer_state_store.mark_detached(
   buf)
   attached_buffers[buf] = nil end

function buffer_state_store.is_attached(buf)
   return attached_buffers[buf] == true
end

function buffer_state_store.list_attached()
   return vim.tbl_keys(attached_buffers)
end

return buffer_state_store
