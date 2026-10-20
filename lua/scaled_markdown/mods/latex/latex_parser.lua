local LATEX_ACCENT_MARKS =
  require 'scaled_markdown.mods.latex.latex_accent_marks'
local LATEX_ENVIRONMENTS =
  require 'scaled_markdown.mods.latex.latex_environments'
local LATEX_FONT_ALPHABETS =
  require 'scaled_markdown.mods.latex.latex_font_alphabets'
local LATEX_LIMIT_OPERATORS =
  require 'scaled_markdown.mods.latex.latex_limit_operators'
local LATEX_NODE_KIND_ENUM =
  require 'scaled_markdown.mods.latex.latex_node_kind_enum'
local LATEX_TOKEN_KIND_ENUM =
  require 'scaled_markdown.mods.latex.latex_token_kind_enum'
local latex_font_styler = require 'scaled_markdown.mods.latex.latex_font_styler'
local latex_tokenizer = require 'scaled_markdown.mods.latex.latex_tokenizer'

local OPTION_OPEN = '['
local OPTION_CLOSE = ']'
local EMPTY_DELIMITER = '.'
local CELL_SEPARATOR = '&'
local ROW_SEPARATOR_COMMAND = '\\'
local SQUARE_ROOT_COMMAND = 'sqrt'
local BINOMIAL_COMMAND = 'binom'
local BEGIN_COMMAND = 'begin'
local END_COMMAND = 'end'
local LEFT_COMMAND = 'left'
local RIGHT_COMMAND = 'right'
local BLANK_PATTERN = '^%s*$'

---@type table<string, string>
local CHARACTER_REPLACEMENTS = {
  ["'"] = '′',
  ['-'] = '−',
  ['~'] = ' ',
  ['&'] = '',
}

---@type table<string, boolean>
local FRACTION_COMMANDS = {
  frac = true,
  dfrac = true,
  tfrac = true,
  cfrac = true,
}

---@type table<string, boolean>
local TEXT_COMMANDS = {
  text = true,
  textrm = true,
  textit = true,
  textbf = true,
  textsf = true,
  texttt = true,
  textnormal = true,
  mathrm = true,
  mbox = true,
  operatorname = true,
}

---@type table<string, boolean>
local DELIMITER_SIZING_COMMANDS = {
  big = true,
  Big = true,
  bigg = true,
  Bigg = true,
  bigl = true,
  bigr = true,
  Bigl = true,
  Bigr = true,
  biggl = true,
  biggr = true,
  Biggl = true,
  Biggr = true,
}

---@class latex_parser
local latex_parser = {}

local parse_atom

---@param text string
---@return LatexNodeProps
local function text_node(text)
  return { kind = LATEX_NODE_KIND_ENUM.TEXT, text = text }
end

---@param children LatexNodeProps[]
---@return LatexNodeProps
local function row_node(children)
  return { kind = LATEX_NODE_KIND_ENUM.ROW, children = children }
end

---@param state LatexParserStateProps
---@return LatexTokenProps?
local function peek(state) return state.tokens[state.position] end

---@param state LatexParserStateProps
---@return LatexTokenProps
local function advance(state)
  local token = state.tokens[state.position]
  state.position = state.position + 1
  return token
end

---@param token LatexTokenProps?
---@param kind LatexTokenKindEnum
---@param value? string
---@return boolean
local function is_token(token, kind, value)
  return token ~= nil
    and token.kind == kind
    and (value == nil or token.value == value)
end

---@param state LatexParserStateProps
local function skip_whitespace(state)
  while is_token(peek(state), LATEX_TOKEN_KIND_ENUM.WHITESPACE) do
    advance(state)
  end
end

---@param node LatexNodeProps?
---@return boolean
local function is_blank_text(node)
  return node ~= nil
    and node.kind == LATEX_NODE_KIND_ENUM.TEXT
    and node.text:match(BLANK_PATTERN) ~= nil
end

---@param token LatexTokenProps
---@return boolean
local function is_group_close(token)
  return token.kind == LATEX_TOKEN_KIND_ENUM.GROUP_CLOSE
end

---@param token LatexTokenProps
---@return boolean
local function is_option_close(token)
  return is_token(token, LATEX_TOKEN_KIND_ENUM.CHARACTER, OPTION_CLOSE)
end

---@param token LatexTokenProps
---@return boolean
local function is_cell_separator(token)
  return is_token(token, LATEX_TOKEN_KIND_ENUM.CHARACTER, CELL_SEPARATOR)
end

---@param token LatexTokenProps
---@return boolean
local function is_row_separator(token)
  return is_token(token, LATEX_TOKEN_KIND_ENUM.COMMAND, ROW_SEPARATOR_COMMAND)
end

---@param state LatexParserStateProps
---@return LatexNodeProps?
local function parse_argument(state)
  skip_whitespace(state)
  local token = peek(state)
  if
    not token
    or token.kind == LATEX_TOKEN_KIND_ENUM.GROUP_CLOSE
    or token.kind == LATEX_TOKEN_KIND_ENUM.SUPERSCRIPT
    or token.kind == LATEX_TOKEN_KIND_ENUM.SUBSCRIPT
  then
    return nil
  end
  return parse_atom(state)
end

---@param children LatexNodeProps[]
---@param token LatexTokenProps
---@param argument LatexNodeProps
local function attach_script(children, token, argument)
  while is_blank_text(children[#children]) do
    table.remove(children)
  end
  local is_superscript = token.kind == LATEX_TOKEN_KIND_ENUM.SUPERSCRIPT
  local slot = is_superscript and 'superscript' or 'subscript'
  local previous = children[#children]
  if
    previous
    and previous.kind == LATEX_NODE_KIND_ENUM.SCRIPT
    and previous[slot] == nil
  then
    previous[slot] = argument
    return
  end
  local base = table.remove(children) or text_node ''
  children[#children + 1] = {
    kind = LATEX_NODE_KIND_ENUM.SCRIPT,
    base = base,
    [slot] = argument,
    is_subscript_first = not is_superscript,
  }
end

---@param state LatexParserStateProps
---@param should_stop fun(token: LatexTokenProps): boolean
---@return LatexNodeProps
local function parse_row(state, should_stop)
  ---@type LatexNodeProps[]
  local children = {}
  local token = peek(state)
  while token and not should_stop(token) do
    if
      token.kind == LATEX_TOKEN_KIND_ENUM.SUPERSCRIPT
      or token.kind == LATEX_TOKEN_KIND_ENUM.SUBSCRIPT
    then
      advance(state)
      local argument = parse_argument(state)
      if argument then
        attach_script(children, token, argument)
      else
        children[#children + 1] = text_node(token.value)
      end
    else
      children[#children + 1] = parse_atom(state)
    end
    token = peek(state)
  end
  return row_node(children)
end

---@param state LatexParserStateProps
---@return LatexNodeProps
local function parse_group_body(state)
  local body = parse_row(state, is_group_close)
  if is_token(peek(state), LATEX_TOKEN_KIND_ENUM.GROUP_CLOSE) then
    advance(state)
  end
  return body
end

---@param state LatexParserStateProps
---@return string?
local function parse_raw_argument(state)
  skip_whitespace(state)
  local token = peek(state)
  if not token or token.kind == LATEX_TOKEN_KIND_ENUM.GROUP_CLOSE then
    return nil
  end
  advance(state)
  if token.kind ~= LATEX_TOKEN_KIND_ENUM.GROUP_OPEN then
    return latex_tokenizer.to_source(token)
  end
  ---@type string[]
  local parts = {}
  local depth = 1
  token = peek(state)
  while token do
    advance(state)
    if token.kind == LATEX_TOKEN_KIND_ENUM.GROUP_OPEN then
      depth = depth + 1
    elseif token.kind == LATEX_TOKEN_KIND_ENUM.GROUP_CLOSE then
      depth = depth - 1
      if depth == 0 then break end
    end
    parts[#parts + 1] = latex_tokenizer.to_source(token)
    token = peek(state)
  end
  return table.concat(parts)
end

---@param state LatexParserStateProps
---@param should_stop fun(token: LatexTokenProps): boolean
---@return LatexNodeProps[][]
local function parse_table_rows(state, should_stop)
  ---@param token LatexTokenProps
  ---@return boolean
  local function ends_cell(token)
    return should_stop(token)
      or is_cell_separator(token)
      or is_row_separator(token)
  end
  ---@type LatexNodeProps[][]
  local rows = {}
  ---@type LatexNodeProps[]
  local cells = {}
  while true do
    cells[#cells + 1] = parse_row(state, ends_cell)
    local token = peek(state)
    if token and is_cell_separator(token) then
      advance(state)
    else
      rows[#rows + 1] = cells
      cells = {}
      if not token or not is_row_separator(token) then break end
      advance(state)
    end
  end
  return rows
end

---@param rows LatexNodeProps[][]
---@param environment LatexEnvironmentProps
---@return LatexNodeProps
local function table_or_single_cell(rows, environment)
  if #rows == 1 and #rows[1] == 1 then return rows[1][1] end
  return {
    kind = LATEX_NODE_KIND_ENUM.TABLE,
    rows = rows,
    environment = environment,
  }
end

---@param state LatexParserStateProps
---@return LatexNodeProps
local function parse_environment(state)
  local environment_name = parse_raw_argument(state) or ''
  local environment = LATEX_ENVIRONMENTS.BY_NAME[environment_name]
    or LATEX_ENVIRONMENTS.DEFAULT
  if environment.has_column_spec then parse_raw_argument(state) end
  local rows = parse_table_rows(
    state,
    function(token)
      return is_token(token, LATEX_TOKEN_KIND_ENUM.COMMAND, END_COMMAND)
    end
  )
  if is_token(peek(state), LATEX_TOKEN_KIND_ENUM.COMMAND, END_COMMAND) then
    advance(state)
    parse_raw_argument(state)
  end
  return {
    kind = LATEX_NODE_KIND_ENUM.TABLE,
    rows = rows,
    environment = environment,
  }
end

---@param state LatexParserStateProps
---@return string
local function parse_delimiter(state)
  skip_whitespace(state)
  local token = peek(state)
  if
    not token
    or token.kind == LATEX_TOKEN_KIND_ENUM.WHITESPACE
    or token.kind == LATEX_TOKEN_KIND_ENUM.GROUP_OPEN
    or token.kind == LATEX_TOKEN_KIND_ENUM.GROUP_CLOSE
  then
    return ''
  end
  advance(state)
  if token.kind == LATEX_TOKEN_KIND_ENUM.COMMAND then
    return state.command_symbols[token.value]
      or latex_tokenizer.to_source(token)
  end
  if token.value == EMPTY_DELIMITER then return '' end
  return token.value
end

---@param state LatexParserStateProps
---@return LatexNodeProps
local function parse_delimited(state)
  local left_delimiter = parse_delimiter(state)
  local body = parse_row(
    state,
    function(token)
      return is_token(token, LATEX_TOKEN_KIND_ENUM.COMMAND, RIGHT_COMMAND)
    end
  )
  local right_delimiter = ''
  if is_token(peek(state), LATEX_TOKEN_KIND_ENUM.COMMAND, RIGHT_COMMAND) then
    advance(state)
    right_delimiter = parse_delimiter(state)
  end
  return {
    kind = LATEX_NODE_KIND_ENUM.DELIMITED,
    left_delimiter = left_delimiter,
    right_delimiter = right_delimiter,
    body = body,
  }
end

---@param state LatexParserStateProps
---@param command_source string
---@param kind LatexNodeKindEnum
---@return LatexNodeProps
local function parse_two_arguments(state, command_source, kind)
  local numerator = parse_argument(state)
  if not numerator then return text_node(command_source) end
  local denominator = parse_argument(state)
  if not denominator then
    return row_node { text_node(command_source), numerator }
  end
  return { kind = kind, numerator = numerator, denominator = denominator }
end

---@param state LatexParserStateProps
---@return LatexNodeProps
local function parse_root(state)
  skip_whitespace(state)
  ---@type LatexNodeProps?
  local index
  if is_token(peek(state), LATEX_TOKEN_KIND_ENUM.CHARACTER, OPTION_OPEN) then
    advance(state)
    index = parse_row(state, is_option_close)
    if is_token(peek(state), LATEX_TOKEN_KIND_ENUM.CHARACTER, OPTION_CLOSE) then
      advance(state)
    end
  end
  return {
    kind = LATEX_NODE_KIND_ENUM.ROOT,
    index = index,
    radicand = parse_argument(state),
  }
end

---@param node LatexNodeProps
---@param alphabet LatexFontAlphabetProps
---@return LatexNodeProps
local function apply_font(node, alphabet)
  if node.kind == LATEX_NODE_KIND_ENUM.TEXT then
    return text_node(latex_font_styler.apply(node.text, alphabet))
  end
  ---@type LatexNodeProps
  local styled_node = vim.deepcopy(node)
  for _, field in ipairs {
    'base',
    'superscript',
    'subscript',
    'numerator',
    'denominator',
    'index',
    'radicand',
    'body',
  } do
    if styled_node[field] then
      styled_node[field] = apply_font(styled_node[field], alphabet)
    end
  end
  for child_index, child in ipairs(styled_node.children or {}) do
    styled_node.children[child_index] = apply_font(child, alphabet)
  end
  return styled_node
end

---@param state LatexParserStateProps
---@param token LatexTokenProps
---@return LatexNodeProps
local function parse_command(state, token)
  local name = token.value
  local command_source = latex_tokenizer.to_source(token)
  if FRACTION_COMMANDS[name] then
    return parse_two_arguments(
      state,
      command_source,
      LATEX_NODE_KIND_ENUM.FRACTION
    )
  end
  if name == BINOMIAL_COMMAND then
    return parse_two_arguments(
      state,
      command_source,
      LATEX_NODE_KIND_ENUM.BINOMIAL
    )
  end
  if name == SQUARE_ROOT_COMMAND then return parse_root(state) end
  if TEXT_COMMANDS[name] then
    return text_node(parse_raw_argument(state) or '')
  end
  if name == BEGIN_COMMAND then return parse_environment(state) end
  if name == END_COMMAND then
    parse_raw_argument(state)
    return text_node ''
  end
  if name == LEFT_COMMAND then return parse_delimited(state) end
  if name == RIGHT_COMMAND or DELIMITER_SIZING_COMMANDS[name] then
    return text_node(parse_delimiter(state))
  end
  local accent_mark = LATEX_ACCENT_MARKS[name]
  if accent_mark then
    local body = parse_argument(state)
    if not body then return text_node(command_source) end
    return {
      kind = LATEX_NODE_KIND_ENUM.ACCENT,
      accent_mark = accent_mark,
      body = body,
    }
  end
  local font_alphabet = LATEX_FONT_ALPHABETS[name]
  if font_alphabet then
    local body = parse_argument(state)
    if not body then return text_node(command_source) end
    return apply_font(body, font_alphabet)
  end
  local symbol = state.command_symbols[name]
  if symbol and LATEX_LIMIT_OPERATORS[name] then
    return { kind = LATEX_NODE_KIND_ENUM.LIMIT_OPERATOR, text = symbol }
  end
  return text_node(symbol or command_source)
end

---@param state LatexParserStateProps
---@return LatexNodeProps
parse_atom = function(state)
  local token = advance(state)
  if token.kind == LATEX_TOKEN_KIND_ENUM.WHITESPACE then
    return text_node ' '
  end
  if token.kind == LATEX_TOKEN_KIND_ENUM.CHARACTER then
    return text_node(CHARACTER_REPLACEMENTS[token.value] or token.value)
  end
  if token.kind == LATEX_TOKEN_KIND_ENUM.GROUP_OPEN then
    return parse_group_body(state)
  end
  if token.kind == LATEX_TOKEN_KIND_ENUM.COMMAND then
    return parse_command(state, token)
  end
  return text_node(token.value)
end

---@param source string
---@param command_symbols table<string, string>
---@return LatexNodeProps
function latex_parser.parse(source, command_symbols)
  ---@type LatexParserStateProps
  local state = {
    tokens = latex_tokenizer.tokenize(source),
    position = 1,
    command_symbols = command_symbols,
  }
  local rows = parse_table_rows(state, function() return false end)
  return table_or_single_cell(rows, LATEX_ENVIRONMENTS.DEFAULT)
end

return latex_parser
