local CORE_CONSTANTS = require 'scaled_markdown.core.constants'
local art_lines_parser =
  require 'scaled_markdown.core.text_art.art_lines_parser'
local process_runner = require 'scaled_markdown.core.text_art.process_runner'

local FIGLET_EXECUTABLE = 'figlet'

---@class figlet_renderer: TextArtRendererProps
local figlet_renderer = {}

---@return boolean
function figlet_renderer.is_available()
  return vim.fn.executable(FIGLET_EXECUTABLE) == 1
end

---@param text string
---@param style_props TextArtStyleProps
---@param width integer
---@param on_done fun(art: TextArtProps?)
function figlet_renderer.render_async(text, style_props, width, on_done)
  local command = {
    FIGLET_EXECUTABLE,
    '-f',
    style_props.font,
    '-w',
    tostring(width),
    '--',
    text,
  }
  process_runner.run_async(
    command,
    { text = true, timeout = CORE_CONSTANTS.TEXT_ART_TIMEOUT_MS },
    ---@param result vim.SystemCompleted
    function(result)
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

return figlet_renderer
