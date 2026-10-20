local LATEX_ARROW_SYMBOLS =
  require 'scaled_markdown.mods.latex.latex_arrow_symbols'
local LATEX_FUNCTION_SYMBOLS =
  require 'scaled_markdown.mods.latex.latex_function_symbols'
local LATEX_GREEK_SYMBOLS =
  require 'scaled_markdown.mods.latex.latex_greek_symbols'
local LATEX_MISC_SYMBOLS =
  require 'scaled_markdown.mods.latex.latex_misc_symbols'
local LATEX_OPERATOR_SYMBOLS =
  require 'scaled_markdown.mods.latex.latex_operator_symbols'
local LATEX_RELATION_SYMBOLS =
  require 'scaled_markdown.mods.latex.latex_relation_symbols'
local LATEX_SPACING_SYMBOLS =
  require 'scaled_markdown.mods.latex.latex_spacing_symbols'

---@type LatexConfigProps
local DEFAULT_LATEX_CONFIG = {
  center_display_math = false,
  highlight_symbols = true,
  command_symbols = vim.tbl_extend(
    'force',
    {},
    LATEX_GREEK_SYMBOLS,
    LATEX_OPERATOR_SYMBOLS,
    LATEX_RELATION_SYMBOLS,
    LATEX_ARROW_SYMBOLS,
    LATEX_MISC_SYMBOLS,
    LATEX_FUNCTION_SYMBOLS,
    LATEX_SPACING_SYMBOLS
  ),
}

return DEFAULT_LATEX_CONFIG
