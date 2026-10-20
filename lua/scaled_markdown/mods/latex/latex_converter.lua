local latex_box_renderer =
  require 'scaled_markdown.mods.latex.latex_box_renderer'
local latex_linear_renderer =
  require 'scaled_markdown.mods.latex.latex_linear_renderer'
local latex_parser = require 'scaled_markdown.mods.latex.latex_parser'
local utf8_text = require 'scaled_markdown.core.text.utf8_text'

---@class latex_converter
local latex_converter = {}

---@param source string
---@param command_symbols table<string, string>
---@return string
function latex_converter.convert(source, command_symbols)
  return utf8_text.trim(
    latex_linear_renderer.render(latex_parser.parse(source, command_symbols))
  )
end

---@param source string
---@param command_symbols table<string, string>
---@return LatexBoxProps
function latex_converter.layout(source, command_symbols)
  return latex_box_renderer.render(latex_parser.parse(source, command_symbols))
end

return latex_converter
