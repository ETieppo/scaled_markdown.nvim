
local LANGUAGE_ENUM = require('scaled_markdown.core.enums.language_enum')
local DEFAULT_IMAGE_CONFIG = require('scaled_markdown.mods.image.default_config')
local IMAGE_QUERY = require('scaled_markdown.mods.image.query')
local image_highlight = require('scaled_markdown.mods.image.highlight')
local image_render = require('scaled_markdown.mods.image.render')

local IMAGE_MOD = {
   name = 'image',
   language = LANGUAGE_ENUM.MARKDOWN_INLINE,
   query = IMAGE_QUERY,
   default_config = DEFAULT_IMAGE_CONFIG,
   highlights = image_highlight.DEFINITIONS,
   render = image_render.render,
}

return IMAGE_MOD
