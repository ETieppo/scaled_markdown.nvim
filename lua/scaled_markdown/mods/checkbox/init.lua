
local LANGUAGE_ENUM = require('scaled_markdown.core.enums.language_enum')
local CHECKBOX_QUERY = require('scaled_markdown.mods.checkbox.query')
local DEFAULT_CHECKBOX_CONFIG =
require('scaled_markdown.mods.checkbox.default_config')
local checkbox_highlight = require('scaled_markdown.mods.checkbox.highlight')
local checkbox_render = require('scaled_markdown.mods.checkbox.render')

local CHECKBOX_MOD = {
   name = 'checkbox',
   language = LANGUAGE_ENUM.MARKDOWN,
   query = CHECKBOX_QUERY,
   default_config = DEFAULT_CHECKBOX_CONFIG,
   highlights = checkbox_highlight.DEFINITIONS,
   render = checkbox_render.render,
}

return CHECKBOX_MOD
