local type ModProps = require 'scaled_markdown.core.types.mod_props'
local LANGUAGE_ENUM = require 'scaled_markdown.core.enums.language_enum'
local DEFAULT_THEMATIC_BREAK_CONFIG =
  require 'scaled_markdown.mods.thematic_break.default_config'
local THEMATIC_BREAK_QUERY = require 'scaled_markdown.mods.thematic_break.query'
local thematic_break_render =
  require 'scaled_markdown.mods.thematic_break.render'

local THEMATIC_BREAK_MOD <const>: ModProps = {
  name = 'thematic_break',
  language = LANGUAGE_ENUM.MARKDOWN,
  query = THEMATIC_BREAK_QUERY,
  default_config = DEFAULT_THEMATIC_BREAK_CONFIG,
  render = thematic_break_render.render,
}

return THEMATIC_BREAK_MOD
