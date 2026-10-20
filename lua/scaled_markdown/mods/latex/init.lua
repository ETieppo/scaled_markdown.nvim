local LANGUAGE_ENUM = require 'scaled_markdown.core.enums.language_enum'
local DEFAULT_LATEX_CONFIG = require 'scaled_markdown.mods.latex.default_config'
local LATEX_QUERY = require 'scaled_markdown.mods.latex.query'
local latex_highlight = require 'scaled_markdown.mods.latex.highlight'
local latex_render = require 'scaled_markdown.mods.latex.render'

---@type ModProps
local LATEX_MOD = {
  name = 'latex',
  language = LANGUAGE_ENUM.MARKDOWN_INLINE,
  query = LATEX_QUERY,
  default_config = DEFAULT_LATEX_CONFIG,
  highlights = latex_highlight.DEFINITIONS,
  render = latex_render.render,
}

return LATEX_MOD
