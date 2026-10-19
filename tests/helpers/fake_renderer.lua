local RENDERER_ENUM = require 'scaled_markdown.core.enums.renderer_enum'
local stub = require 'harness.stub'

local ART_HEIGHT = 2
local COLUMNS_PER_CHARACTER = 2
local ART_CHARACTER = '#'
local RENDERER_MODULE_FORMAT = 'scaled_markdown.core.text_art.%s_renderer'
---@type RendererEnum[]
local TEXT_ART_RENDERERS = {
  RENDERER_ENUM.GRAPHICS,
  RENDERER_ENUM.TYPEFACE,
  RENDERER_ENUM.TOILET,
  RENDERER_ENUM.FIGLET,
}

---@class fake_renderer
---@field ART_HEIGHT integer
---@field COLUMNS_PER_CHARACTER integer
local fake_renderer = {}

---@param text string
---@return TextArtProps
local function build_art(text)
  local line = string.rep(ART_CHARACTER, #text * COLUMNS_PER_CHARACTER)
  ---@type string[]
  local lines = {}
  for index = 1, ART_HEIGHT do
    lines[index] = line
  end
  return { lines = lines }
end

---@param renderer RendererEnum
---@param options OptionsProps
---@return CallProps[]
function fake_renderer.install(renderer, options)
  local renderer_module = require(RENDERER_MODULE_FORMAT:format(renderer))
  ---@type CallProps[]
  local calls = {}
  stub.replace(
    renderer_module,
    'is_available',
    ---@return boolean
    function() return options.available ~= false end
  )
  stub.replace(
    renderer_module,
    'render_async',
    ---@param text string
    ---@param style_props TextArtStyleProps
    ---@param width integer
    ---@param on_done fun(art: TextArtProps?)
    function(text, style_props, width, on_done)
      calls[#calls + 1] = { text = text, style = style_props, width = width }
      vim.schedule(function()
        if options.fails then
          on_done(nil)
        else
          on_done(build_art(text))
        end
      end)
    end
  )
  return calls
end

function fake_renderer.install_all_unavailable()
  for _, renderer in ipairs(TEXT_ART_RENDERERS) do
    fake_renderer.install(renderer, { available = false })
  end
end

fake_renderer.ART_HEIGHT = ART_HEIGHT
fake_renderer.COLUMNS_PER_CHARACTER = COLUMNS_PER_CHARACTER

return fake_renderer
