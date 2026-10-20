---@type table<string, boolean>
local LATEX_LIMIT_OPERATORS = {
  lim = true,
  limsup = true,
  liminf = true,
  max = true,
  min = true,
  sup = true,
  inf = true,
  det = true,
  gcd = true,
  Pr = true,
  sum = true,
  prod = true,
  coprod = true,
  bigcup = true,
  bigcap = true,
  bigvee = true,
  bigwedge = true,
  bigoplus = true,
  bigotimes = true,
  bigodot = true,
  biguplus = true,
}

return LATEX_LIMIT_OPERATORS
