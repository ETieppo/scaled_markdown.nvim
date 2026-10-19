---@class CoreConstantsProps
---@field PLUGIN_NAME string
---@field NAMESPACE_NAME string
---@field AUGROUP_NAME string
---@field BUFFER_AUGROUP_PREFIX string
---@field COMMAND_NAME string
---@field GRADIENT_HIGHLIGHT_PREFIX string
---@field PADDING_HIGHLIGHT string
---@field RENDER_DEBOUNCE_MS integer
---@field VIEWPORT_MARGIN_LINES integer
---@field TEXT_ART_TIMEOUT_MS integer
---@field UNBOUNDED_TEXT_ART_WIDTH integer

---@type CoreConstantsProps
local CORE_CONSTANTS = {
  PLUGIN_NAME = 'scaled_markdown',
  NAMESPACE_NAME = 'scaled_markdown',
  AUGROUP_NAME = 'ScaledMarkdown',
  BUFFER_AUGROUP_PREFIX = 'ScaledMarkdownBuffer',
  COMMAND_NAME = 'ScaledMarkdown',
  GRADIENT_HIGHLIGHT_PREFIX = 'ScaledMarkdownGradient',
  PADDING_HIGHLIGHT = 'Normal',
  RENDER_DEBOUNCE_MS = 25,
  VIEWPORT_MARGIN_LINES = 40,
  TEXT_ART_TIMEOUT_MS = 3000,
  UNBOUNDED_TEXT_ART_WIDTH = 4000,
}

return CORE_CONSTANTS
