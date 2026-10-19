---@type table<string, boolean>
local KITTY_GRAPHICS_TERM_PROGRAMS =
  { ghostty = true, WezTerm = true, kitty = true }
---@type string[]
local KITTY_GRAPHICS_TERM_PATTERNS = { 'kitty', 'ghostty' }

---@class terminal_capability
local terminal_capability = {}

---@return boolean
local function matches_known_terminal()
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

---@return boolean
function terminal_capability.supports_kitty_graphics()
  return vim.env.TMUX == nil
    and vim.o.termguicolors
    and #vim.api.nvim_list_uis() > 0
    and matches_known_terminal()
end

return terminal_capability
