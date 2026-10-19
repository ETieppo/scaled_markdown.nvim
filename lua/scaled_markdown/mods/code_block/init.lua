local LANGUAGE_ENUM = require 'scaled_markdown.core.enums.language_enum'
local CODE_BLOCK_QUERY = require 'scaled_markdown.mods.code_block.query'
local DEFAULT_CODE_BLOCK_CONFIG =
  require 'scaled_markdown.mods.code_block.default_config'
local code_block_render = require 'scaled_markdown.mods.code_block.render'

---@type ModProps
local CODE_BLOCK_MOD = {
  name = 'code_block',
  language = LANGUAGE_ENUM.MARKDOWN,
  query = CODE_BLOCK_QUERY,
  default_config = DEFAULT_CODE_BLOCK_CONFIG,
  render = code_block_render.render,
}

return CODE_BLOCK_MOD
