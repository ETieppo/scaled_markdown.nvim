
local LANGUAGE_ENUM = require('scaled_markdown.core.enums.language_enum')
local DEFAULT_LINK_REFERENCE_CONFIG =
require('scaled_markdown.mods.link_reference.default_config')
local LINK_REFERENCE_QUERY = require('scaled_markdown.mods.link_reference.query')
local link_reference_highlight =
require('scaled_markdown.mods.link_reference.highlight')
local link_reference_render =
require('scaled_markdown.mods.link_reference.render')

local LINK_REFERENCE_MOD = {
   name = 'link_reference',
   language = LANGUAGE_ENUM.MARKDOWN,
   query = LINK_REFERENCE_QUERY,
   default_config = DEFAULT_LINK_REFERENCE_CONFIG,
   highlights = link_reference_highlight.DEFINITIONS,
   render = link_reference_render.render,
}

return LINK_REFERENCE_MOD
