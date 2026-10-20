local SELF_DRAWN_SYMBOLS = 'octant+solid+half+quad+eighth'
local FONT_DRAWN_SYMBOLS = 'solid+half+quad+eighth'
---@type table<string, boolean>
local FONT_DRAWN_TERM_PROGRAMS = { Apple_Terminal = true }

---@class terminal_symbol_support
local terminal_symbol_support = {}

---@return string
function terminal_symbol_support.default_symbols()
  if FONT_DRAWN_TERM_PROGRAMS[vim.env.TERM_PROGRAM or ''] then
    return FONT_DRAWN_SYMBOLS
  end
  return SELF_DRAWN_SYMBOLS
end

return terminal_symbol_support
