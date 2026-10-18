local CORE_CONSTANTS = require('scaled_markdown.core.constants')
local buffer_attachment =
require('scaled_markdown.core.buffer.buffer_attachment')
local config_store = require('scaled_markdown.core.config.config_store')

local autocmd_registry = {}


local function should_auto_attach(buf)
   local config = config_store.get()
   return config.enabled and
   vim.tbl_contains(config.file_types, vim.bo[buf].filetype)
end

function autocmd_registry.register(
   on_colorscheme_changed,
   on_exit)

   local augroup_id =
   vim.api.nvim_create_augroup(CORE_CONSTANTS.AUGROUP_NAME, { clear = true })

   vim.api.nvim_create_autocmd('FileType', {
      group = augroup_id,
      pattern = config_store.get().file_types,
      callback = function(event)
         if
should_auto_attach(event.buf) and
            not buffer_attachment.is_attached(event.buf) then

            buffer_attachment.attach(event.buf)
         end
      end,
   })

   vim.api.nvim_create_autocmd('ColorScheme', {
      group = augroup_id,
      callback = function()
         on_colorscheme_changed()
         buffer_attachment.refresh_all()
      end,
   })

   vim.api.nvim_create_autocmd('VimLeavePre', {
      group = augroup_id,
      callback = on_exit,
   })
end

function autocmd_registry.attach_existing_buffers()
   for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) and should_auto_attach(buf) then
         buffer_attachment.attach(buf)
      end
   end
end

return autocmd_registry
