local KITTY_GRAPHICS_TERM_PROGRAMS <const>: {string: boolean} =
  { ghostty = true, WezTerm = true, kitty = true }
local KITTY_GRAPHICS_TERM_PATTERNS <const>: {string} = { 'kitty', 'ghostty' }

local record terminal_capability
end

local function matches_known_terminal(): boolean
  if
    vim.env.KITTY_WINDOW_ID
    or KITTY_GRAPHICS_TERM_PROGRAMS[vim.env.TERM_PROGRAM or '']
  then
    return true
  end
  local term = vim.env.TERM or ''
  for _, pattern in ipairs(KITTY_GRAPHICS_TERM_PATTERNS) do
    if term:find(pattern, 1, true) then return true end
  end
  return false
end

function terminal_capability.supports_kitty_graphics(): boolean
  return vim.env.TMUX == nil
    and vim.o.termguicolors
    and #vim.api.nvim_list_uis() > 0
    and matches_known_terminal()
end

return terminal_capability
