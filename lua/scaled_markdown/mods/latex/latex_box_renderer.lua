local LATEX_COLUMN_ALIGNMENT_ENUM =
  require 'scaled_markdown.mods.latex.latex_column_alignment_enum'
local LATEX_DELIMITER_PIECES =
  require 'scaled_markdown.mods.latex.latex_delimiter_pieces'
local LATEX_NODE_KIND_ENUM =
  require 'scaled_markdown.mods.latex.latex_node_kind_enum'
local LATEX_SPACED_OPERATORS =
  require 'scaled_markdown.mods.latex.latex_spaced_operators'
local latex_box = require 'scaled_markdown.mods.latex.latex_box'
local latex_linear_renderer =
  require 'scaled_markdown.mods.latex.latex_linear_renderer'
local latex_script_formatter =
  require 'scaled_markdown.mods.latex.latex_script_formatter'
local utf8_text = require 'scaled_markdown.core.text.utf8_text'

local FRACTION_RULE = '─'
local FRACTION_PADDING = 1
local SHORT_ROOT_BAR = '_'
local TALL_ROOT_CORNER = '┌'
local TALL_ROOT_BAR = '─'
local TALL_ROOT_STEM = '│'
local TALL_ROOT_FOOT = '╲'
local BINOMIAL_LEFT_DELIMITER = '('
local BINOMIAL_RIGHT_DELIMITER = ')'
local BLANK_PATTERN = '^%s*$'
local OPERATOR_SPACE = ' '

---@type table<string, boolean>
local UNARY_CONTEXT_CHARACTERS = {
  ['('] = true,
  ['['] = true,
  ['{'] = true,
  [','] = true,
  ['|'] = true,
}

---@class latex_box_renderer
local latex_box_renderer = {}

local render_node

---@param node LatexNodeProps
---@return boolean
local function is_blank_text(node)
  return node.kind == LATEX_NODE_KIND_ENUM.TEXT
    and node.text:match(BLANK_PATTERN) ~= nil
end

---@param children LatexNodeProps[]
---@return LatexNodeProps[]
local function trim_blank_edges(children)
  local first_index, last_index = 1, #children
  while first_index <= last_index and is_blank_text(children[first_index]) do
    first_index = first_index + 1
  end
  while last_index >= first_index and is_blank_text(children[last_index]) do
    last_index = last_index - 1
  end
  ---@type LatexNodeProps[]
  local trimmed_children = {}
  for child_index = first_index, last_index do
    trimmed_children[#trimmed_children + 1] = children[child_index]
  end
  return trimmed_children
end

---@param node LatexNodeProps?
---@return boolean
local function is_spaced_operator(node)
  return node ~= nil
    and node.kind == LATEX_NODE_KIND_ENUM.TEXT
    and LATEX_SPACED_OPERATORS[node.text] == true
end

---@param node LatexNodeProps?
---@return boolean
local function starts_operand(node)
  if not node or is_spaced_operator(node) then return false end
  if node.kind ~= LATEX_NODE_KIND_ENUM.TEXT then return true end
  return not UNARY_CONTEXT_CHARACTERS[node.text]
end

---@param nodes LatexNodeProps[]
local function drop_trailing_blanks(nodes)
  while nodes[#nodes] and is_blank_text(nodes[#nodes]) do
    table.remove(nodes)
  end
end

---@param children LatexNodeProps[]
---@return LatexNodeProps[]
local function space_operators(children)
  ---@type LatexNodeProps[]
  local spaced_children = {}
  ---@type LatexNodeProps?
  local previous_visible
  local follows_spaced_operator = false
  for _, child in ipairs(children) do
    if is_blank_text(child) then
      if not follows_spaced_operator then
        spaced_children[#spaced_children + 1] = child
      end
    elseif is_spaced_operator(child) and starts_operand(previous_visible) then
      drop_trailing_blanks(spaced_children)
      spaced_children[#spaced_children + 1] = {
        kind = LATEX_NODE_KIND_ENUM.TEXT,
        text = OPERATOR_SPACE .. child.text .. OPERATOR_SPACE,
      }
      follows_spaced_operator = true
      previous_visible = child
    else
      spaced_children[#spaced_children + 1] = child
      follows_spaced_operator = false
      previous_visible = child
    end
  end
  return spaced_children
end

---@param children LatexNodeProps[]
---@return LatexBoxProps
local function render_row(children)
  ---@type LatexBoxProps[]
  local boxes = {}
  for _, child in ipairs(space_operators(trim_blank_edges(children))) do
    boxes[#boxes + 1] = render_node(child)
  end
  return latex_box.join_horizontal(boxes)
end

---@param delimiter string
---@param height integer
---@param baseline integer
---@return LatexBoxProps?
local function build_delimiter_column(delimiter, height, baseline)
  if delimiter == '' then return nil end
  if height == 1 then return latex_box.from_text(delimiter) end
  local pieces = LATEX_DELIMITER_PIECES[delimiter]
  local width = utf8_text.display_width(delimiter)
  ---@type string[]
  local lines = {}
  for line_index = 1, height do
    if not pieces then
      lines[line_index] = line_index == baseline and delimiter
        or string.rep(' ', width)
    elseif height == 2 and pieces.short_top then
      lines[line_index] = line_index == 1 and pieces.short_top
        or pieces.short_bottom
    elseif line_index == 1 then
      lines[line_index] = pieces.top
    elseif line_index == height then
      lines[line_index] = pieces.bottom
    elseif pieces.middle and line_index == math.ceil(height / 2) then
      lines[line_index] = pieces.middle
    else
      lines[line_index] = pieces.extender
    end
  end
  return { lines = lines, width = width, baseline = baseline }
end

---@param left_delimiter string
---@param body LatexBoxProps
---@param right_delimiter string
---@return LatexBoxProps
local function wrap_with_delimiters(left_delimiter, body, right_delimiter)
  ---@type LatexBoxProps[]
  local boxes = {}
  local height = #body.lines
  local left_column =
    build_delimiter_column(left_delimiter, height, body.baseline)
  if left_column then boxes[#boxes + 1] = left_column end
  boxes[#boxes + 1] = body
  local right_column =
    build_delimiter_column(right_delimiter, height, body.baseline)
  if right_column then boxes[#boxes + 1] = right_column end
  return latex_box.join_horizontal(boxes)
end

---@param node LatexNodeProps
---@return LatexBoxProps
local function render_fraction(node)
  local numerator = render_node(node.numerator)
  local denominator = render_node(node.denominator)
  local width = math.max(numerator.width, denominator.width)
    + 2 * FRACTION_PADDING
  return latex_box.stack({
    numerator,
    latex_box.from_text(string.rep(FRACTION_RULE, width)),
    denominator,
  }, #numerator.lines + 1, LATEX_COLUMN_ALIGNMENT_ENUM.CENTER)
end

---@param node LatexNodeProps
---@return LatexBoxProps
local function render_binomial(node)
  local total = render_node(node.numerator)
  local chosen = render_node(node.denominator)
  return wrap_with_delimiters(
    BINOMIAL_LEFT_DELIMITER,
    latex_box.stack(
      { total, chosen },
      #total.lines,
      LATEX_COLUMN_ALIGNMENT_ENUM.CENTER
    ),
    BINOMIAL_RIGHT_DELIMITER
  )
end

---@param node LatexNodeProps
---@param base LatexBoxProps
---@return LatexBoxProps
local function render_limits(node, base)
  ---@type LatexBoxProps[]
  local boxes = {}
  local baseline = base.baseline
  if node.superscript then
    local superscript =
      latex_box.from_text(latex_linear_renderer.render(node.superscript))
    boxes[#boxes + 1] = superscript
    baseline = baseline + #superscript.lines
  end
  boxes[#boxes + 1] = base
  if node.subscript then
    boxes[#boxes + 1] =
      latex_box.from_text(latex_linear_renderer.render(node.subscript))
  end
  return latex_box.stack(boxes, baseline, LATEX_COLUMN_ALIGNMENT_ENUM.CENTER)
end

---@param node LatexNodeProps
---@return LatexBoxProps
local function render_script(node)
  local base = render_node(node.base)
  if node.base.kind == LATEX_NODE_KIND_ENUM.LIMIT_OPERATOR then
    return render_limits(node, base)
  end
  local ascent = base.baseline - 1
  local descent = #base.lines - base.baseline
  local superscript_text = node.superscript
    and latex_linear_renderer.render(node.superscript)
  local subscript_text = node.subscript
    and latex_linear_renderer.render(node.subscript)
  local mapped_superscript = superscript_text
    and latex_script_formatter.to_superscript(superscript_text)
  local mapped_subscript = subscript_text
    and latex_script_formatter.to_subscript(subscript_text)
  if
    mapped_superscript
    and mapped_subscript
    and ascent == 0
    and descent == 0
  then
    return latex_box.join_horizontal {
      base,
      latex_box.from_text(
        node.is_subscript_first and mapped_subscript .. mapped_superscript
          or mapped_superscript .. mapped_subscript
      ),
    }
  end
  ---@type LatexScriptPlacementProps[]
  local placements = {}
  if superscript_text then
    placements[#placements + 1] = {
      box = latex_box.from_text(mapped_superscript or superscript_text),
      shift = mapped_superscript and ascent or ascent + 1,
    }
  end
  if subscript_text then
    placements[#placements + 1] = {
      box = latex_box.from_text(mapped_subscript or subscript_text),
      shift = mapped_subscript and -descent or -(descent + 1),
    }
  end
  return latex_box.join_horizontal {
    base,
    latex_box.place_vertically(placements),
  }
end

---@param node LatexNodeProps
---@return LatexBoxProps
local function render_root(node)
  if not node.radicand then
    return latex_box.from_text(latex_linear_renderer.root_symbol(node.index))
  end
  local radicand = render_node(node.radicand)
  if #radicand.lines == 1 then
    local root_symbol = latex_linear_renderer.root_symbol(node.index)
    local symbol_width = utf8_text.display_width(root_symbol)
    return {
      lines = {
        string.rep(' ', symbol_width)
          .. string.rep(SHORT_ROOT_BAR, radicand.width),
        root_symbol .. radicand.lines[1],
      },
      width = symbol_width + radicand.width,
      baseline = 2,
    }
  end
  local index_text = node.index and latex_linear_renderer.render(node.index)
    or ''
  local foot = (latex_script_formatter.to_superscript(index_text) or index_text)
    .. TALL_ROOT_FOOT
  local foot_width = utf8_text.display_width(foot)
  local indentation = string.rep(' ', foot_width)
  ---@type string[]
  local lines = {
    indentation
      .. TALL_ROOT_CORNER
      .. string.rep(TALL_ROOT_BAR, radicand.width),
  }
  for line_index, line in ipairs(radicand.lines) do
    local prefix = line_index == #radicand.lines and foot or indentation
    lines[#lines + 1] = prefix .. TALL_ROOT_STEM .. line
  end
  return {
    lines = lines,
    width = foot_width + 1 + radicand.width,
    baseline = radicand.baseline + 1,
  }
end

---@param node LatexNodeProps
---@return LatexBoxProps
local function render_accent(node)
  local body = render_node(node.body)
  if #body.lines > 1 then return body end
  return latex_box.from_text(
    latex_linear_renderer.apply_accent(body.lines[1], node.accent_mark)
  )
end

---@param node LatexNodeProps
---@return LatexBoxProps
local function render_table(node)
  local environment = node.environment --[[@as LatexEnvironmentProps]]
  local alignments = environment.column_alignments
  ---@type LatexBoxProps[][]
  local cell_boxes = {}
  ---@type integer[]
  local column_widths = {}
  for row_index, cells in ipairs(node.rows or {}) do
    cell_boxes[row_index] = {}
    for column_index, cell in ipairs(cells) do
      local cell_box = render_node(cell)
      cell_boxes[row_index][column_index] = cell_box
      column_widths[column_index] =
        math.max(column_widths[column_index] or 0, cell_box.width)
    end
  end
  ---@type LatexBoxProps[]
  local row_boxes = {}
  for row_index = 1, #cell_boxes do
    ---@type LatexBoxProps[]
    local parts = {}
    for column_index, column_width in ipairs(column_widths) do
      if column_index > 1 and environment.column_gap > 0 then
        parts[#parts + 1] = latex_box.blank(environment.column_gap)
      end
      parts[#parts + 1] = latex_box.align(
        cell_boxes[row_index][column_index] or latex_box.empty(),
        column_width,
        alignments[(column_index - 1) % #alignments + 1]
      )
    end
    row_boxes[row_index] = latex_box.join_horizontal(parts)
  end
  local total_height = 0
  for _, row_box in ipairs(row_boxes) do
    total_height = total_height + #row_box.lines
  end
  return wrap_with_delimiters(
    environment.left_delimiter,
    latex_box.stack(
      row_boxes,
      math.ceil(total_height / 2),
      LATEX_COLUMN_ALIGNMENT_ENUM.LEFT
    ),
    environment.right_delimiter
  )
end

---@param node LatexNodeProps
---@return LatexBoxProps
render_node = function(node)
  local kind = node.kind
  if
    kind == LATEX_NODE_KIND_ENUM.TEXT
    or kind == LATEX_NODE_KIND_ENUM.LIMIT_OPERATOR
  then
    return latex_box.from_text(node.text)
  end
  if kind == LATEX_NODE_KIND_ENUM.ROW then return render_row(node.children) end
  if kind == LATEX_NODE_KIND_ENUM.SCRIPT then return render_script(node) end
  if kind == LATEX_NODE_KIND_ENUM.FRACTION then return render_fraction(node) end
  if kind == LATEX_NODE_KIND_ENUM.BINOMIAL then return render_binomial(node) end
  if kind == LATEX_NODE_KIND_ENUM.ROOT then return render_root(node) end
  if kind == LATEX_NODE_KIND_ENUM.ACCENT then return render_accent(node) end
  if kind == LATEX_NODE_KIND_ENUM.DELIMITED then
    return wrap_with_delimiters(
      node.left_delimiter,
      render_node(node.body),
      node.right_delimiter
    )
  end
  return render_table(node)
end

---@param node LatexNodeProps
---@return LatexBoxProps
function latex_box_renderer.render(node) return render_node(node) end

return latex_box_renderer
