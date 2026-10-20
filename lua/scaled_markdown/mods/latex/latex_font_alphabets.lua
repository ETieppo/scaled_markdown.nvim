---@type LatexFontAlphabetProps
local BOLD_ALPHABET = {
  uppercase_start = 0x1D400,
  lowercase_start = 0x1D41A,
  digit_start = 0x1D7CE,
  exceptions = {},
}

---@type LatexFontAlphabetProps
local SCRIPT_ALPHABET = {
  uppercase_start = 0x1D49C,
  lowercase_start = 0x1D4B6,
  exceptions = {
    B = 'ℬ',
    E = 'ℰ',
    F = 'ℱ',
    H = 'ℋ',
    I = 'ℐ',
    L = 'ℒ',
    M = 'ℳ',
    R = 'ℛ',
    e = 'ℯ',
    g = 'ℊ',
    o = 'ℴ',
  },
}

---@type table<string, LatexFontAlphabetProps>
local LATEX_FONT_ALPHABETS = {
  mathbf = BOLD_ALPHABET,
  boldsymbol = BOLD_ALPHABET,
  mathcal = SCRIPT_ALPHABET,
  mathscr = SCRIPT_ALPHABET,
  mathit = {
    uppercase_start = 0x1D434,
    lowercase_start = 0x1D44E,
    exceptions = { h = 'ℎ' },
  },
  mathfrak = {
    uppercase_start = 0x1D504,
    lowercase_start = 0x1D51E,
    exceptions = {
      C = 'ℭ',
      H = 'ℌ',
      I = 'ℑ',
      R = 'ℜ',
      Z = 'ℨ',
    },
  },
  mathbb = {
    uppercase_start = 0x1D538,
    lowercase_start = 0x1D552,
    digit_start = 0x1D7D8,
    exceptions = {
      C = 'ℂ',
      H = 'ℍ',
      N = 'ℕ',
      P = 'ℙ',
      Q = 'ℚ',
      R = 'ℝ',
      Z = 'ℤ',
    },
  },
  mathsf = {
    uppercase_start = 0x1D5A0,
    lowercase_start = 0x1D5BA,
    digit_start = 0x1D7E2,
    exceptions = {},
  },
  mathtt = {
    uppercase_start = 0x1D670,
    lowercase_start = 0x1D68A,
    digit_start = 0x1D7F6,
    exceptions = {},
  },
}

return LATEX_FONT_ALPHABETS
