local type ModProps = require 'scaled_markdown.core.types.mod_props'
local LANGUAGE_ENUM = require 'scaled_markdown.core.enums.language_enum'
local DEFAULT_LINK_CONFIG = require 'scaled_markdown.mods.link.default_config'
local LINK_QUERY = require 'scaled_markdown.mods.link.query'
local link_highlight = require 'scaled_markdown.mods.link.highlight'
local link_render = require 'scaled_markdown.mods.link.render'

local LINK_MOD <const>: ModProps = {
  name = 'link',
  language = LANGUAGE_ENUM.MARKDOWN_INLINE,
  query = LINK_QUERY,
  default_config = DEFAULT_LINK_CONFIG,
  highlights = link_highlight.DEFINITIONS,
  render = link_render.render,
}

return LINK_MOD
