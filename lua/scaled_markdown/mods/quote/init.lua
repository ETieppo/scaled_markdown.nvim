local LANGUAGE_ENUM = require 'scaled_markdown.core.enums.language_enum'
local DEFAULT_QUOTE_CONFIG = require 'scaled_markdown.mods.quote.default_config'
local QUOTE_QUERY = require 'scaled_markdown.mods.quote.query'
local quote_highlight = require 'scaled_markdown.mods.quote.highlight'
local quote_render = require 'scaled_markdown.mods.quote.render'

---@type ModProps
local QUOTE_MOD = {
  name = 'quote',
  language = LANGUAGE_ENUM.MARKDOWN,
  query = QUOTE_QUERY,
  default_config = DEFAULT_QUOTE_CONFIG,
  highlights = quote_highlight.DEFINITIONS,
  render = quote_render.render,
}

return QUOTE_MOD
