local record CoreConstantsProps
  PLUGIN_NAME: string
  NAMESPACE_NAME: string
  AUGROUP_NAME: string
  BUFFER_AUGROUP_PREFIX: string
  COMMAND_NAME: string
  GRADIENT_HIGHLIGHT_PREFIX: string
  PADDING_HIGHLIGHT: string
  RENDER_DEBOUNCE_MS: integer
  VIEWPORT_MARGIN_LINES: integer
  TEXT_ART_TIMEOUT_MS: integer
  UNBOUNDED_TEXT_ART_WIDTH: integer
end

local CORE_CONSTANTS <const>: CoreConstantsProps = {
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
