local type CaptureProps = require 'scaled_markdown.core.types.capture_props'
local type ModConfigProps =
  require 'scaled_markdown.core.types.mod_config_props'
local type RegisteredModProps =
  require 'scaled_markdown.core.types.registered_mod_props'
local type RenderContextProps =
  require 'scaled_markdown.core.types.render_context_props'
local CORE_CONSTANTS = require 'scaled_markdown.core.constants'
local config_store = require 'scaled_markdown.core.config.config_store'
local extmark_writer = require 'scaled_markdown.core.render.extmark_writer'
local mod_registry = require 'scaled_markdown.core.registry.mod_registry'
local render_context_builder =
  require 'scaled_markdown.core.render.render_context_builder'
local reveal_range = require 'scaled_markdown.core.render.reveal_range'
local treesitter_capture_iterator =
  require 'scaled_markdown.core.parser.treesitter_capture_iterator'
local viewport_range = require 'scaled_markdown.core.render.viewport_range'
local window_geometry = require 'scaled_markdown.core.render.window_geometry'

local record render_pipeline
end

local namespace_id =
  vim.api.nvim_create_namespace(CORE_CONSTANTS.NAMESPACE_NAME)
local reported_mod_failures: {string: boolean} = {}

local function report_mod_failure(mod_name: string, error_message: string)
  if reported_mod_failures[mod_name] then return end
  reported_mod_failures[mod_name] = true
  vim.notify(
    ("[%s] mod '%s' failed: %s"):format(
      CORE_CONSTANTS.PLUGIN_NAME,
      mod_name,
      error_message
    ),
    vim.log.levels.ERROR
  )
end

local function render_mod(
  registered_mod: RegisteredModProps,
  trees_by_language: {string: {vim.TSTreeProps}},
  base_context_dto: RenderContextProps<ModConfigProps>,
  start_row: integer,
  end_row: integer
)
  local mod_name = registered_mod.props.name
  local mod_config = config_store.get_mod_config(mod_name)
  if not mod_config.enabled then return end
  local context_dto =
    render_context_builder.with_mod_config(base_context_dto, mod_config)
  local ok, error_message: boolean, any = pcall(
    treesitter_capture_iterator.for_each_capture,
    trees_by_language,
    registered_mod,
    base_context_dto.buf,
    start_row,
    end_row,
    function(capture_dto: CaptureProps)
      registered_mod.props.render(capture_dto, context_dto)
    end
  )
  if not ok then report_mod_failure(mod_name, tostring(error_message)) end
end

function render_pipeline.namespace_id(): integer return namespace_id end

function render_pipeline.clear(buf: integer)
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_clear_namespace(buf, namespace_id, 0, -1)
  end
end

function render_pipeline.render(buf: integer)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  local win = vim.fn.bufwinid(buf)
  if win == -1 then return end
  local start_row, end_row = viewport_range.resolve(win, buf)
  local trees_by_language =
    treesitter_capture_iterator.collect_trees_by_language(
      buf,
      start_row,
      end_row
    )
  render_pipeline.clear(buf)
  if not trees_by_language then return end
  local revealed_rows =
    reveal_range.collect_revealed_rows(win, config_store.get().reveal)
  local writer = extmark_writer.new(
    buf,
    namespace_id,
    revealed_rows,
    window_geometry.text_offset(win)
  )
  local base_context_dto = render_context_builder.build(buf, win, writer)
  for _, registered_mod in ipairs(mod_registry.list()) do
    render_mod(
      registered_mod,
      trees_by_language,
      base_context_dto,
      start_row,
      end_row
    )
  end
end

return render_pipeline
