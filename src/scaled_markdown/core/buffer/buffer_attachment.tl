local CORE_CONSTANTS = require 'scaled_markdown.core.constants'
local buffer_state_store =
  require 'scaled_markdown.core.buffer.buffer_state_store'
local config_store = require 'scaled_markdown.core.config.config_store'
local render_pipeline = require 'scaled_markdown.core.render.render_pipeline'
local render_scheduler = require 'scaled_markdown.core.autocmd.render_scheduler'
local window_option_guard =
  require 'scaled_markdown.core.window.window_option_guard'

local RENDER_TRIGGER_EVENTS <const>: {string} = {
  'TextChanged',
  'TextChangedI',
  'InsertLeave',
  'CursorMoved',
  'CursorMovedI',
  'ModeChanged',
  'WinScrolled',
  'WinResized',
  'BufWinEnter',
}

local record buffer_attachment
  detach: function(buf?: integer)
end

local function resolve_buffer(buf?: integer): integer
  return (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
end

local function build_augroup_name(buf: integer): string
  return CORE_CONSTANTS.BUFFER_AUGROUP_PREFIX .. buf
end

local function apply_window_options(buf: integer)
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    window_option_guard.apply(win, config_store.get().window_options)
  end
end

local function restore_window_options(buf: integer)
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    window_option_guard.restore(win)
  end
end

local function register_buffer_autocmds(buf: integer)
  local augroup_id =
    vim.api.nvim_create_augroup(build_augroup_name(buf), { clear = true })
  vim.api.nvim_create_autocmd(RENDER_TRIGGER_EVENTS, {
    group = augroup_id,
    buffer = buf,
    callback = function(event: vim.AutocmdEventProps)
      if event.event == 'BufWinEnter' then apply_window_options(buf) end
      render_scheduler.schedule(buf)
    end,
  })
  vim.api.nvim_create_autocmd({ 'BufWipeout', 'BufUnload' }, {
    group = augroup_id,
    buffer = buf,
    callback = function() buffer_attachment.detach(buf) end,
  })
end

function buffer_attachment.attach(buf?: integer)
  buf = resolve_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return end

  buffer_state_store.mark_attached(buf)
  register_buffer_autocmds(buf)
  apply_window_options(buf)
  render_pipeline.render(buf)
end

function buffer_attachment.detach(buf?: integer)
  buf = resolve_buffer(buf)
  buffer_state_store.mark_detached(buf)
  render_scheduler.cancel(buf)

  pcall(vim.api.nvim_del_augroup_by_name, build_augroup_name(buf))
  restore_window_options(buf)
  render_pipeline.clear(buf)
end

function buffer_attachment.toggle(buf?: integer)
  buf = resolve_buffer(buf)
  if buffer_state_store.is_attached(buf) then
    buffer_attachment.detach(buf)
  else
    buffer_attachment.attach(buf)
  end
end

function buffer_attachment.refresh_all()
  for _, buf in ipairs(buffer_state_store.list_attached()) do
    render_pipeline.render(buf)
  end
end

function buffer_attachment.schedule_refresh_all()
  for _, buf in ipairs(buffer_state_store.list_attached()) do
    render_scheduler.schedule(buf)
  end
end

function buffer_attachment.is_attached(buf?: integer): boolean
  return buffer_state_store.is_attached(resolve_buffer(buf))
end

return buffer_attachment
