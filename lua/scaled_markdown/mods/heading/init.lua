local LANGUAGE_ENUM = require 'scaled_markdown.core.enums.language_enum'
local DEFAULT_HEADING_CONFIG =
  require 'scaled_markdown.mods.heading.default_config'
local HEADING_QUERY = require 'scaled_markdown.mods.heading.query'
local heading_highlight = require 'scaled_markdown.mods.heading.highlight'
local heading_render = require 'scaled_markdown.mods.heading.render'

---@type ModProps
local HEADING_MOD = {
  name = 'heading',
  language = LANGUAGE_ENUM.MARKDOWN,
  query = HEADING_QUERY,
  default_config = DEFAULT_HEADING_CONFIG,
  highlights = heading_highlight.build_definitions,
  render = heading_render.render,
}

return HEADING_MOD
