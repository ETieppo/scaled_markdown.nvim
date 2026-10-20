local LATEX_SYMBOL_CLASS_ENUM =
  require 'scaled_markdown.mods.latex.latex_symbol_class_enum'

---@class LatexHighlightGroupsProps
---@field MATH string
---@field BY_SYMBOL_CLASS table<LatexSymbolClassEnum, string>

---@class LatexHighlightProps
---@field GROUPS LatexHighlightGroupsProps
---@field DEFINITIONS HighlightDefinitionsProps

---@class LatexSymbolHighlightProps
---@field group string
---@field link string

---@type table<LatexSymbolClassEnum, LatexSymbolHighlightProps>
local SYMBOL_HIGHLIGHTS = {
  [LATEX_SYMBOL_CLASS_ENUM.NUMBER] = {
    group = 'ScaledMarkdownLatexNumber',
    link = '@number',
  },
  [LATEX_SYMBOL_CLASS_ENUM.OPERATOR] = {
    group = 'ScaledMarkdownLatexOperator',
    link = '@operator',
  },
  [LATEX_SYMBOL_CLASS_ENUM.RELATION] = {
    group = 'ScaledMarkdownLatexRelation',
    link = '@keyword.operator',
  },
  [LATEX_SYMBOL_CLASS_ENUM.GREEK] = {
    group = 'ScaledMarkdownLatexGreek',
    link = '@variable.builtin',
  },
  [LATEX_SYMBOL_CLASS_ENUM.SYMBOL] = {
    group = 'ScaledMarkdownLatexSymbol',
    link = '@constant.builtin',
  },
  [LATEX_SYMBOL_CLASS_ENUM.LARGE_OPERATOR] = {
    group = 'ScaledMarkdownLatexLargeOperator',
    link = '@keyword',
  },
  [LATEX_SYMBOL_CLASS_ENUM.FUNCTION] = {
    group = 'ScaledMarkdownLatexFunction',
    link = '@function.builtin',
  },
  [LATEX_SYMBOL_CLASS_ENUM.DELIMITER] = {
    group = 'ScaledMarkdownLatexDelimiter',
    link = '@punctuation.bracket',
  },
}

---@type LatexHighlightGroupsProps
local LATEX_HIGHLIGHT_GROUPS = {
  MATH = 'ScaledMarkdownLatex',
  BY_SYMBOL_CLASS = {},
}

---@type HighlightDefinitionsProps
local LATEX_HIGHLIGHT_DEFINITIONS = {
  [LATEX_HIGHLIGHT_GROUPS.MATH] = { link = '@markup.math' },
}

for symbol_class, symbol_highlight in pairs(SYMBOL_HIGHLIGHTS) do
  LATEX_HIGHLIGHT_GROUPS.BY_SYMBOL_CLASS[symbol_class] = symbol_highlight.group
  LATEX_HIGHLIGHT_DEFINITIONS[symbol_highlight.group] =
    { link = symbol_highlight.link }
end

---@type LatexHighlightProps
local LATEX_HIGHLIGHT = {
  GROUPS = LATEX_HIGHLIGHT_GROUPS,
  DEFINITIONS = LATEX_HIGHLIGHT_DEFINITIONS,
}

return LATEX_HIGHLIGHT
