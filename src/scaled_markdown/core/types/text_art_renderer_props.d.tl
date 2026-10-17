local type TextArtProps = require 'scaled_markdown.core.types.text_art_props'
local type TextArtStyleProps =
  require 'scaled_markdown.core.types.text_art_style_props'

local interface TextArtRendererProps
  is_available: function(): boolean
  render_async: function(
    text: string,
    style_props: TextArtStyleProps,
    width: integer,
    on_done: function(TextArtProps)
  )
end

return TextArtRendererProps
