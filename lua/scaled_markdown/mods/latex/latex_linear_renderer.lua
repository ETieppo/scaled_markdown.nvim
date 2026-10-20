local LATEX_NODE_KIND_ENUM =
  require 'scaled_markdown.mods.latex.latex_node_kind_enum'
local latex_script_formatter =
  require 'scaled_markdown.mods.latex.latex_script_formatter'
local utf8_text = require 'scaled_markdown.core.text.utf8_text'

local DEFAULT_ROOT_SYMBOL = '√'
local ROOT_OVERLINE_MARK = '\u{0305}'
local FRACTION_SLASH = '⁄'
local INLINE_FRACTION_SLASH = '/'
local SUPERSCRIPT_MARKER = '^'
local SUBSCRIPT_MARKER = '_'
local BINOMIAL_FORMAT = 'C(%s, %s)'
local GROUPED_FORMAT = '(%s)'
local CELL_SEPARATOR = ''
local ROW_SEPARATOR = '   '

---@type table<string, string>
local ROOT_SYMBOLS_BY_INDEX = {
  ['2'] = '√',
  ['3'] = '∛',
  ['4'] = '∜',
}

---@type string[]
local COMPOUND_MARKERS = {
  ' ',
  '+',
  '-',
  '−',
  '±',
  '∓',
  '=',
  '×',
  '÷',
  '⋅',
  '/',
  ',',
  '<',
  '>',
}

---@class latex_linear_renderer
local latex_linear_renderer = {}

local render_node

---@param text string
---@return string
local function group_when_compound(text)
  for _, marker in ipairs(COMPOUND_MARKERS) do
    if text:find(marker, 1, true) then return GROUPED_FORMAT:format(text) end
  end
  return text
end

---@param text string
---@return string
local function group_when_multiple_characters(text)
  if #utf8_text.split_characters(text) > 1 then
    return GROUPED_FORMAT:format(text)
  end
  return text
end

---@param node LatexNodeProps
---@param to_script fun(text: string): string?
---@param marker string
---@return string
local function render_script_part(node, to_script, marker)
  local text = render_node(node)
  return to_script(text) or marker .. group_when_multiple_characters(text)
end

---@param node LatexNodeProps
---@return string
local function render_script(node)
  ---@type string[]
  local parts = {}
  if node.superscript then
    parts[#parts + 1] = render_script_part(
      node.superscript,
      latex_script_formatter.to_superscript,
      SUPERSCRIPT_MARKER
    )
  end
  if node.subscript then
    local subscript_part = render_script_part(
      node.subscript,
      latex_script_formatter.to_subscript,
      SUBSCRIPT_MARKER
    )
    table.insert(
      parts,
      node.is_subscript_first and 1 or #parts + 1,
      subscript_part
    )
  end
  return render_node(node.base) .. table.concat(parts)
end

---@param node LatexNodeProps
---@return string
local function render_fraction(node)
  local numerator = render_node(node.numerator)
  local denominator = render_node(node.denominator)
  local superscript_numerator = latex_script_formatter.to_superscript(numerator)
  local subscript_denominator = latex_script_formatter.to_subscript(denominator)
  if superscript_numerator and subscript_denominator then
    return superscript_numerator .. FRACTION_SLASH .. subscript_denominator
  end
  return group_when_compound(numerator)
    .. INLINE_FRACTION_SLASH
    .. group_when_compound(denominator)
end

---@param index_node LatexNodeProps?
---@return string
function latex_linear_renderer.root_symbol(index_node)
  if not index_node then return DEFAULT_ROOT_SYMBOL end
  local index = render_node(index_node)
  return ROOT_SYMBOLS_BY_INDEX[index]
    or (latex_script_formatter.to_superscript(index) or '')
      .. DEFAULT_ROOT_SYMBOL
end

---@param node LatexNodeProps
---@return string
local function render_root(node)
  local root_symbol = latex_linear_renderer.root_symbol(node.index)
  if not node.radicand then return root_symbol end
  ---@type string[]
  local overlined_characters = {}
  for _, character in
    ipairs(utf8_text.split_characters(render_node(node.radicand)))
  do
    overlined_characters[#overlined_characters + 1] = character
      .. ROOT_OVERLINE_MARK
  end
  return root_symbol .. table.concat(overlined_characters)
end

---@param text string
---@param accent_mark string
---@return string
function latex_linear_renderer.apply_accent(text, accent_mark)
  ---@type string[]
  local accented_characters = {}
  for _, character in ipairs(utf8_text.split_characters(text)) do
    accented_characters[#accented_characters + 1] = character == ' '
        and character
      or character .. accent_mark
  end
  return table.concat(accented_characters)
end

---@param node LatexNodeProps
---@return string
local function render_table(node)
  ---@type string[]
  local row_texts = {}
  local environment = node.environment --[[@as LatexEnvironmentProps]]
  for _, cells in ipairs(node.rows or {}) do
    ---@type string[]
    local cell_texts = {}
    for _, cell in ipairs(cells) do
      cell_texts[#cell_texts + 1] = render_node(cell)
    end
    row_texts[#row_texts + 1] =
      utf8_text.trim(table.concat(cell_texts, CELL_SEPARATOR))
  end
  return environment.left_delimiter
    .. table.concat(row_texts, ROW_SEPARATOR)
    .. environment.right_delimiter
end

---@param children LatexNodeProps[]
---@return string
local function render_children(children)
  ---@type string[]
  local parts = {}
  for _, child in ipairs(children) do
    parts[#parts + 1] = render_node(child)
  end
  return table.concat(parts)
end

---@param node LatexNodeProps
---@return string
render_node = function(node)
  local kind = node.kind
  if
    kind == LATEX_NODE_KIND_ENUM.TEXT
    or kind == LATEX_NODE_KIND_ENUM.LIMIT_OPERATOR
  then
    return node.text
  end
  if kind == LATEX_NODE_KIND_ENUM.ROW then
    return render_children(node.children)
  end
  if kind == LATEX_NODE_KIND_ENUM.SCRIPT then return render_script(node) end
  if kind == LATEX_NODE_KIND_ENUM.FRACTION then return render_fraction(node) end
  if kind == LATEX_NODE_KIND_ENUM.BINOMIAL then
    return BINOMIAL_FORMAT:format(
      render_node(node.numerator),
      render_node(node.denominator)
    )
  end
  if kind == LATEX_NODE_KIND_ENUM.ROOT then return render_root(node) end
  if kind == LATEX_NODE_KIND_ENUM.ACCENT then
    return latex_linear_renderer.apply_accent(
      render_node(node.body),
      node.accent_mark
    )
  end
  if kind == LATEX_NODE_KIND_ENUM.DELIMITED then
    return node.left_delimiter .. render_node(node.body) .. node.right_delimiter
  end
  return render_table(node)
end

---@param node LatexNodeProps
---@return string
function latex_linear_renderer.render(node) return render_node(node) end

return latex_linear_renderer
