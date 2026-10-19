local gradient_palette =
  require 'scaled_markdown.core.highlight.gradient_palette'
local highlight_definer =
  require 'scaled_markdown.core.highlight.highlight_definer'
local mod_registry = require 'scaled_markdown.core.registry.mod_registry'

---@class highlight_setup
local highlight_setup = {}

function highlight_setup.apply()
  gradient_palette.define_groups()
  highlight_definer.define_all(mod_registry.collect_highlights())
end

return highlight_setup
