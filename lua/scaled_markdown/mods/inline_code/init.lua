
local LANGUAGE_ENUM = require('scaled_markdown.core.enums.language_enum')
local DEFAULT_INLINE_CODE_CONFIG =
require('scaled_markdown.mods.inline_code.default_config')
local INLINE_CODE_QUERY = require('scaled_markdown.mods.inline_code.query')
local inline_code_highlight =
require('scaled_markdown.mods.inline_code.highlight')
local inline_code_render = require('scaled_markdown.mods.inline_code.render')

local INLINE_CODE_MOD = {
   name = 'inline_code',
   language = LANGUAGE_ENUM.MARKDOWN_INLINE,
   query = INLINE_CODE_QUERY,
   default_config = DEFAULT_INLINE_CODE_CONFIG,
   highlights = inline_code_highlight.DEFINITIONS,
   render = inline_code_render.render,
}

return INLINE_CODE_MOD
