local type WindowOptionsProps =
  require 'scaled_markdown.core.types.window_options_props'

local record window_option_guard
end

local saved_options_by_window: {integer: WindowOptionsProps} = {}

function window_option_guard.apply(
  win: integer,
  window_options: WindowOptionsProps
)
  if not vim.api.nvim_win_is_valid(win) then return end
  local saved_options = saved_options_by_window[win] or {}
  for option_name, option_value in pairs(window_options) do
    if saved_options[option_name] == nil then
      saved_options[option_name] =
        vim.api.nvim_get_option_value(option_name, { win = win })
    end
    vim.api.nvim_set_option_value(
      option_name,
      option_value,
      { scope = 'local', win = win }
    )
  end
  saved_options_by_window[win] = saved_options
end

function window_option_guard.restore(win: integer)
  local saved_options = saved_options_by_window[win]
  saved_options_by_window[win] = nil
  if not saved_options or not vim.api.nvim_win_is_valid(win) then return end
  for option_name, option_value in pairs(saved_options) do
    vim.api.nvim_set_option_value(
      option_name,
      option_value,
      { scope = 'local', win = win }
    )
  end
end

return window_option_guard
