---@type table<string, string>
local LATEX_SPACING_SYMBOLS = {
  [','] = ' ',
  [':'] = ' ',
  [';'] = ' ',
  ['!'] = '',
  [' '] = ' ',
  ['\\'] = ' ',
  quad = '  ',
  qquad = '    ',
  ['{'] = '{',
  ['}'] = '}',
  ['|'] = '‖',
  ['%'] = '%',
  ['$'] = '$',
  ['#'] = '#',
  ['&'] = '&',
  ['_'] = '_',
  displaystyle = '',
  textstyle = '',
  scriptstyle = '',
  limits = '',
  nolimits = '',
  nonumber = '',
  notag = '',
}

return LATEX_SPACING_SYMBOLS
