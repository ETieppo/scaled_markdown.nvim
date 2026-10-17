local record buffer_state_store
end

local attached_buffers: {integer: boolean} = {}

function buffer_state_store.mark_attached(
  buf: integer
) attached_buffers[buf] = true end

function buffer_state_store.mark_detached(
  buf: integer
) attached_buffers[buf] = nil end

function buffer_state_store.is_attached(buf: integer): boolean
  return attached_buffers[buf] == true
end

function buffer_state_store.list_attached(): {integer}
  return vim.tbl_keys(attached_buffers)
end

return buffer_state_store
