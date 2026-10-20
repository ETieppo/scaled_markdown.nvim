local GRAPHICS_PROTOCOL_ENUM =
  require 'scaled_markdown.core.enums.graphics_protocol_enum'
local RENDERER_ENUM = require 'scaled_markdown.core.enums.renderer_enum'
local config_store = require 'scaled_markdown.core.config.config_store'
local graphics_renderer =
  require 'scaled_markdown.core.text_art.graphics_renderer'
local neovim_version = require 'scaled_markdown.core.setup.neovim_version'
local terminal_capability =
  require 'scaled_markdown.core.terminal.terminal_capability'
local terminal_cell_size =
  require 'scaled_markdown.core.terminal.terminal_cell_size'
local toilet_renderer = require 'scaled_markdown.core.text_art.toilet_renderer'
local figlet_renderer = require 'scaled_markdown.core.text_art.figlet_renderer'
local typeface_renderer =
  require 'scaled_markdown.core.text_art.typeface_renderer'

---@type string[]
local REQUIRED_PARSERS = { 'markdown', 'markdown_inline' }
---@type table<RendererEnum, fun(): boolean>
local AVAILABILITY_BY_RENDERER = {
  [RENDERER_ENUM.GRAPHICS] = graphics_renderer.is_available,
  [RENDERER_ENUM.TYPEFACE] = typeface_renderer.is_available,
  [RENDERER_ENUM.TOILET] = toilet_renderer.is_available,
  [RENDERER_ENUM.FIGLET] = figlet_renderer.is_available,
}
---@type RendererEnum[]
local RENDERER_REPORT_ORDER = {
  RENDERER_ENUM.GRAPHICS,
  RENDERER_ENUM.TYPEFACE,
  RENDERER_ENUM.TOILET,
  RENDERER_ENUM.FIGLET,
}

---@class health_report
local health_report = {}

local function report_neovim_version()
  local requirement = ('neovim %s or newer'):format(
    neovim_version.MINIMUM_VERSION_TEXT
  )
  if neovim_version.is_supported() then
    vim.health.ok(requirement)
  else
    vim.health.error(requirement .. ' is required')
  end
end

local function report_parsers()
  for _, parser_name in ipairs(REQUIRED_PARSERS) do
    if vim.treesitter.language.add(parser_name) then
      vim.health.ok(("treesitter parser '%s' found"):format(parser_name))
    else
      vim.health.error(("treesitter parser '%s' missing"):format(parser_name))
    end
  end
end

local function report_renderers()
  vim.health.info(
    ('configured renderer: %s'):format(config_store.get().renderer)
  )
  for _, renderer in ipairs(RENDERER_REPORT_ORDER) do
    if AVAILABILITY_BY_RENDERER[renderer]() then
      vim.health.ok(("renderer '%s' available"):format(renderer))
    else
      vim.health.warn(("renderer '%s' unavailable"):format(renderer))
    end
  end
end

local function report_terminal()
  local capability = terminal_capability.detect()
  if capability.is_inside_tmux then vim.health.info 'running inside tmux' end
  if capability.protocol ~= GRAPHICS_PROTOCOL_ENUM.NONE then
    vim.health.ok(('graphics protocol: %s'):format(capability.protocol))
  else
    vim.health.warn(
      ('graphics unavailable: %s'):format(capability.unsupported_reason)
    )
  end
  local measured_size = terminal_cell_size.measure()
  local resolved_size = terminal_cell_size.resolve()
  if measured_size then
    vim.health.ok(
      ('cell size measured: %dx%d px'):format(
        measured_size.width,
        measured_size.height
      )
    )
  else
    vim.health.warn(
      ('cell size not measurable, using %dx%d px; set terminal.cell_width_pixels/cell_height_pixels'):format(
        resolved_size.width,
        resolved_size.height
      )
    )
  end
end

function health_report.run()
  vim.health.start 'scaled_markdown'
  report_neovim_version()
  report_parsers()
  report_renderers()
  report_terminal()
end

return health_report
