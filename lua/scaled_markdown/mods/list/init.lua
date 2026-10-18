
local LANGUAGE_ENUM = require('scaled_markdown.core.enums.language_enum')
local DEFAULT_LIST_CONFIG = require('scaled_markdown.mods.list.default_config')
local LIST_QUERY = require('scaled_markdown.mods.list.query')
local list_highlight = require('scaled_markdown.mods.list.highlight')
local list_render = require('scaled_markdown.mods.list.render')

local LIST_MOD = {
   name = 'list',
   language = LANGUAGE_ENUM.MARKDOWN,
   query = LIST_QUERY,
   default_config = DEFAULT_LIST_CONFIG,
   highlights = list_highlight.DEFINITIONS,
   render = list_render.render,
}

return LIST_MOD
