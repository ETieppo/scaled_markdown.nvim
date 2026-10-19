local type CaptureProps = require 'scaled_markdown.core.types.capture_props'
local type ModConfigProps =
  require 'scaled_markdown.core.types.mod_config_props'
local type RenderContextProps =
  require 'scaled_markdown.core.types.render_context_props'
local type CalloutMatchProps =
  require 'scaled_markdown.mods.quote.callout_match_props'
local type ExtmarkWriterProps =
  require 'scaled_markdown.core.types.extmark_writer_props'
local type QuoteConfigProps = require 'scaled_markdown.mods.quote.config_props'
local gradient_palette =
  require 'scaled_markdown.core.highlight.gradient_palette'
local quote_highlight = require 'scaled_markdown.mods.quote.highlight'

local BLOCK_QUOTE_NODE_TYPE <const> = 'block_quote'
local QUOTE_MARKER_BYTE <const> = ('>'):byte()
local QUOTE_PREFIX_PATTERN <const> = '^[%s>]*'
local CALLOUT_MARKER_PATTERN <const> = '()%[!(%a+)%]()'

local type QuoteContextProps = RenderContextProps<QuoteConfigProps>

local record quote_render
end

local function is_nested_quote(node: vim.TSNodeProps): boolean
  local ancestor = node:parent()
  while ancestor do
    if ancestor:type() == BLOCK_QUOTE_NODE_TYPE then return true end
    ancestor = ancestor:parent()
  end
  return false
end

local function resolve_last_row(capture_dto: CaptureProps): integer
  return capture_dto.end_col == 0 and capture_dto.end_row - 1
    or capture_dto.end_row
end

local function find_callout(
  first_line: string,
  mod_config: QuoteConfigProps
): CalloutMatchProps
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
    highlight = quote_highlight.GROUPS.CALLOUT_BY_TYPE[callout_type:upper()],
    start_col = math.floor(tonumber(marker_start)) - 1,
    end_col = math.floor(tonumber(marker_end)) - 1,
  }
end

local function render_bars(
  row: integer,
  line: string,
  bar_text: string,
  highlight_group: string,
  writer: ExtmarkWriterProps
)
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

local function render_callout_title(
  row: integer,
  callout: CalloutMatchProps,
  writer: ExtmarkWriterProps
)
  writer.set_extmark(row, callout.start_col, {
    end_col = callout.end_col,
    conceal = '',
  })
  writer.set_extmark(row, callout.start_col, {
    virt_text = {
      { callout.props.icon .. callout.props.title, callout.highlight },
    },
    virt_text_pos = 'inline',
  })
end

function quote_render.render(
  capture_dto: CaptureProps,
  mod_context_dto: RenderContextProps<ModConfigProps>
)
  local context_dto = mod_context_dto as QuoteContextProps
  if is_nested_quote(capture_dto.node) then return end
  local first_row, last_row =
    capture_dto.start_row, resolve_last_row(capture_dto)
  local row_count = last_row - first_row + 1
  local callout =
    find_callout(context_dto.line_at(first_row), context_dto.mod_config)
  for row = first_row, last_row do
    local highlight_group = callout and callout.highlight
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
