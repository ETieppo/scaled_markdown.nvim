local gradient_palette =
  require 'scaled_markdown.core.highlight.gradient_palette'

local BLOCK_QUOTE_NODE_TYPE = 'block_quote'
local QUOTE_MARKER_BYTE = ('>'):byte()
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
