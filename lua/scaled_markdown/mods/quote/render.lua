local CORE_CONSTANTS = require 'scaled_markdown.core.constants'
local LANGUAGE_ENUM = require 'scaled_markdown.core.enums.language_enum'
local gradient_palette =
  require 'scaled_markdown.core.highlight.gradient_palette'

local BLOCK_QUOTE_NODE_TYPE = 'block_quote'
local QUOTE_MARKER = '>'
local QUOTE_MARKER_BYTE = QUOTE_MARKER:byte()
local QUOTE_PREFIX_PATTERN = '^[%s>]*'
local CALLOUT_MARKER_PATTERN = '()%[!(%a+)%]()'

---@alias QuoteContextProps RenderContextProps<QuoteConfigProps>

---@class quote_render
local quote_render = {}

---@param node TSNode
---@return boolean
local function is_nested_quote(node)
  local ancestor = node:parent()
  while ancestor do
    if ancestor:type() == BLOCK_QUOTE_NODE_TYPE then return true end
    ancestor = ancestor:parent()
  end
  return false
end

---@param capture_dto CaptureProps
---@return integer
local function resolve_last_row(capture_dto)
  return capture_dto.end_col == 0 and capture_dto.end_row - 1
    or capture_dto.end_row
end

---@param first_line string
---@param mod_config QuoteConfigProps
---@return CalloutMatchProps?
local function find_callout(first_line, mod_config)
  local prefix = first_line:match(QUOTE_PREFIX_PATTERN)
  local marker_start, callout_type, marker_end =
    first_line:match(CALLOUT_MARKER_PATTERN, #prefix + 1)
  if not callout_type or tonumber(marker_start) ~= #prefix + 1 then
    return nil
  end
  local callout_props = mod_config.callouts[callout_type:upper()]
  if not callout_props then return nil end
  return {
    props = callout_props,
    start_col = math.floor(tonumber(marker_start) --[[@as number]]) - 1,
    end_col = math.floor(tonumber(marker_end) --[[@as number]]) - 1,
  }
end

---@param row integer
---@param line string
---@param bar_text string
---@param highlight_group string
---@param writer ExtmarkWriterProps
local function render_bars(row, line, bar_text, highlight_group, writer)
  local prefix = line:match(QUOTE_PREFIX_PATTERN)
  for byte_index = 1, #prefix do
    if prefix:byte(byte_index) == QUOTE_MARKER_BYTE then
      writer.set_extmark(row, byte_index - 1, {
        virt_text = { { bar_text, highlight_group } },
        virt_text_pos = 'overlay',
      })
    end
  end
end

---@param row integer
---@param callout CalloutMatchProps
---@param writer ExtmarkWriterProps
local function render_callout_title(row, callout, writer)
  writer.set_extmark(row, callout.start_col, {
    end_col = callout.end_col,
    conceal = '',
  })
  writer.set_extmark(row, callout.start_col, {
    virt_text = {
      { callout.props.icon .. callout.props.title, callout.props.color },
    },
    virt_text_pos = 'inline',
  })
end

---@param buf integer
---@param row integer
---@param col integer
---@return TSNode?
local function find_outermost_quote(buf, row, col)
  local ok, parser =
    pcall(vim.treesitter.get_parser, buf, LANGUAGE_ENUM.MARKDOWN)
  if not ok or not parser then return nil end
  local tree = parser:trees()[1]
  if not tree then return nil end
  local node = tree:root():named_descendant_for_range(row, col, row, col)
  ---@type TSNode?
  local outermost_quote
  while node do
    if node:type() == BLOCK_QUOTE_NODE_TYPE then outermost_quote = node end
    node = node:parent()
  end
  return outermost_quote
end

---@param row integer
---@param prefix_col integer
---@param mod_context_dto RenderContextProps<ModConfigProps>
---@return [string, string][]?
function quote_render.decorate_line_prefix(row, prefix_col, mod_context_dto)
  ---@type QuoteContextProps
  local context_dto = mod_context_dto
  local line = context_dto.line_at(row)
  local prefix = line:match(QUOTE_PREFIX_PATTERN):sub(1, prefix_col)
  local first_marker_col = prefix:find(QUOTE_MARKER, 1, true)
  if not first_marker_col then return nil end
  local quote_node =
    find_outermost_quote(context_dto.buf, row, first_marker_col - 1)
  if not quote_node then return nil end
  local first_row = quote_node:start()
  local _, _, end_row, end_col = quote_node:range()
  local last_row = end_col == 0 and end_row - 1 or end_row
  local callout =
    find_callout(context_dto.line_at(first_row), context_dto.mod_config)
  local highlight_group = callout and callout.props.color
    or gradient_palette.group_for_position(
      row - first_row,
      last_row - first_row + 1
    )
  ---@type [string, string][]
  local chunks = {}
  for byte_index = 1, #prefix do
    chunks[#chunks + 1] = prefix:byte(byte_index) == QUOTE_MARKER_BYTE
        and { context_dto.mod_config.bar, highlight_group }
      or { ' ', CORE_CONSTANTS.PADDING_HIGHLIGHT }
  end
  return chunks
end

---@param capture_dto CaptureProps
---@param mod_context_dto RenderContextProps<ModConfigProps>
function quote_render.render(capture_dto, mod_context_dto)
  ---@type QuoteContextProps
  local context_dto = mod_context_dto
  if is_nested_quote(capture_dto.node) then return end
  local first_row, last_row =
    capture_dto.start_row, resolve_last_row(capture_dto)
  local row_count = last_row - first_row + 1
  local callout =
    find_callout(context_dto.line_at(first_row), context_dto.mod_config)
  for row = first_row, last_row do
    local highlight_group = callout and callout.props.color
      or gradient_palette.group_for_position(row - first_row, row_count)
    render_bars(
      row,
      context_dto.line_at(row),
      context_dto.mod_config.bar,
      highlight_group,
      context_dto.writer
    )
  end
  if callout then
    render_callout_title(first_row, callout, context_dto.writer)
  end
end

return quote_render
