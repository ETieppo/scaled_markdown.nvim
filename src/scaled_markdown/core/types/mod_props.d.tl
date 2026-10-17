local type CaptureProps = require 'scaled_markdown.core.types.capture_props'
local type HighlightDefinitionsProps =
  require 'scaled_markdown.core.types.highlight_definitions_props'
local LANGUAGE_ENUM = require 'scaled_markdown.core.enums.language_enum'
local type LanguageEnum = LANGUAGE_ENUM.LanguageEnum
local type ModConfigProps =
  require 'scaled_markdown.core.types.mod_config_props'
local type RenderContextProps =
  require 'scaled_markdown.core.types.render_context_props'

local record ModProps
  name: string
  language: LanguageEnum
  query: string
  default_config: ModConfigProps
  highlights: HighlightDefinitionsProps | function(): HighlightDefinitionsProps
  render: function(
    capture_dto: CaptureProps,
    context_dto: RenderContextProps<ModConfigProps>
  )
end

return ModProps
