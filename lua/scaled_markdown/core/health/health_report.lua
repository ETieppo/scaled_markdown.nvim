local RendererEnum = require 'scaled_markdown.core.enums.renderer_enum'
local config_store = require 'scaled_markdown.core.config.config_store'

local REQUIRED_PARSERS = { 'markdown', 'markdown_inline' }

local RENDERER_REPORT_ORDER = {
  RendererEnum.GRAPHICS,
  RendererEnum.TYPEFACE,
  RendererEnum.TOILET,
  RendererEnum.FIGLET,
}

local health_report = {}

local function report_parsers()
  for _, parser_name in ipairs(REQUIRED_PARSERS) do
    if vim.treesitter.language.add(parser_name) then
      vim.health.ok(("treesitter parser '%s' found"):format(parser_name))
    else
      vim.health.error(("treesitter parser '%s' missing"):format(parser_name))
    end
  end
end

function health_report.run()
  vim.health.start 'scaled_markdown'
  report_parsers()
end

return health_report
