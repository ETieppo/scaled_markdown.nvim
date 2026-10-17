local type TextArtProps = require 'scaled_markdown.core.types.text_art_props'
local type TextArtRendererProps =
  require 'scaled_markdown.core.types.text_art_renderer_props'
local type TextArtStyleProps =
  require 'scaled_markdown.core.types.text_art_style_props'
local CORE_CONSTANTS = require 'scaled_markdown.core.constants'
local art_lines_parser =
  require 'scaled_markdown.core.text_art.art_lines_parser'
local process_runner = require 'scaled_markdown.core.text_art.process_runner'

local TOILET_EXECUTABLE <const> = 'toilet'

local record toilet_renderer is TextArtRendererProps
end

function toilet_renderer.is_available(): boolean
  return vim.fn.executable(TOILET_EXECUTABLE) == 1
end

function toilet_renderer.render_async(
  text: string,
  style_props: TextArtStyleProps,
  width: integer,
  on_done: function(TextArtProps)
)
  local command = {
    TOILET_EXECUTABLE,
    '--font',
    style_props.font,
    '--width',
    tostring(width),
    '--',
    text,
  }
  process_runner.run_async(
    command,
    { text = true, timeout = CORE_CONSTANTS.TEXT_ART_TIMEOUT_MS },
    function(result: vim.SystemCompletedProps)
      if result.code ~= 0 then
        on_done(nil)
        return
      end
      local art_lines = art_lines_parser.trim_blank_edges(
        art_lines_parser.split_lines(result.stdout)
      )
      on_done(art_lines_parser.to_result(art_lines))
    end
  )
end

return toilet_renderer
