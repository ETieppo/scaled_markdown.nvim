---@class LatexDelimiterPiecesProps
---@field top string
---@field extender string
---@field bottom string
---@field middle? string
---@field short_top? string
---@field short_bottom? string

---@type table<string, LatexDelimiterPiecesProps>
local LATEX_DELIMITER_PIECES = {
  ['('] = { top = '⎛', extender = '⎜', bottom = '⎝' },
  [')'] = { top = '⎞', extender = '⎟', bottom = '⎠' },
  ['['] = { top = '⎡', extender = '⎢', bottom = '⎣' },
  [']'] = { top = '⎤', extender = '⎥', bottom = '⎦' },
  ['{'] = {
    top = '⎧',
    extender = '⎪',
    bottom = '⎩',
    middle = '⎨',
    short_top = '⎰',
    short_bottom = '⎱',
  },
  ['}'] = {
    top = '⎫',
    extender = '⎪',
    bottom = '⎭',
    middle = '⎬',
    short_top = '⎱',
    short_bottom = '⎰',
  },
  ['⌈'] = { top = '⎡', extender = '⎢', bottom = '⎢' },
  ['⌉'] = { top = '⎤', extender = '⎥', bottom = '⎥' },
  ['⌊'] = { top = '⎢', extender = '⎢', bottom = '⎣' },
  ['⌋'] = { top = '⎥', extender = '⎥', bottom = '⎦' },
  ['|'] = { top = '│', extender = '│', bottom = '│' },
  ['‖'] = { top = '‖', extender = '‖', bottom = '‖' },
  ['⟨'] = { top = '╱', extender = ' ', bottom = '╲', middle = '⟨' },
  ['⟩'] = { top = '╲', extender = ' ', bottom = '╱', middle = '⟩' },
}

return LATEX_DELIMITER_PIECES
