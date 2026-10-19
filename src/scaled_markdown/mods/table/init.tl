local type ModProps = require 'scaled_markdown.core.types.mod_props'
local LANGUAGE_ENUM = require 'scaled_markdown.core.enums.language_enum'
local DEFAULT_TABLE_CONFIG = require 'scaled_markdown.mods.table.default_config'
local TABLE_QUERY = require 'scaled_markdown.mods.table.query'
local table_highlight = require 'scaled_markdown.mods.table.highlight'
local table_render = require 'scaled_markdown.mods.table.render'

local TABLE_MOD <const>: ModProps = {
  name = 'table',
  language = LANGUAGE_ENUM.MARKDOWN,
  query = TABLE_QUERY,
  default_config = DEFAULT_TABLE_CONFIG,
  highlights = table_highlight.DEFINITIONS,
  render = table_render.render,
}

return TABLE_MOD
