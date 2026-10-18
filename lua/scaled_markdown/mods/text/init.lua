
local LANGUAGE_ENUM = require('scaled_markdown.core.enums.language_enum')
local DEFAULT_TEXT_CONFIG = require('scaled_markdown.mods.text.default_config')
local TEXT_QUERY = require('scaled_markdown.mods.text.query')
local text_highlight = require('scaled_markdown.mods.text.highlight')
local text_render = require('scaled_markdown.mods.text.render')

local TEXT_MOD = {
   name = 'text',
   language = LANGUAGE_ENUM.MARKDOWN_INLINE,
   query = TEXT_QUERY,
   default_config = DEFAULT_TEXT_CONFIG,
   highlights = text_highlight.DEFINITIONS,
   render = text_render.render,
}

return TEXT_MOD
