local CORE_CONSTANTS = require 'scaled_markdown.core.constants'
local config_store = require 'scaled_markdown.core.config.config_store'
local utf8_text = require 'scaled_markdown.core.text.utf8_text'

---@class line_prefix_decorator
local line_prefix_decorator = {}

---@param line_at fun(row: integer): string
---@param row integer
---@param prefix_col integer
---@return [string, string][]
local function build_blank_prefix(line_at, row, prefix_col)
  local prefix_width = utf8_text.display_width(line_at(row):sub(1, prefix_col))
  return { { string.rep(' ', prefix_width), CORE_CONSTANTS.PADDING_HIGHLIGHT } }
end

---@param registered_mods RegisteredModProps[]
---@param line_at fun(row: integer): string
---@param build_mod_context fun(mod_config: ModConfigProps): RenderContextProps<ModConfigProps>
---@return fun(row: integer, prefix_col: integer): [string, string][]
function line_prefix_decorator.new(registered_mods, line_at, build_mod_context)
  return function(row, prefix_col)
    for _, registered_mod in ipairs(registered_mods) do
      local decorate = registered_mod.props.decorate_line_prefix
      local mod_config = config_store.get_mod_config(registered_mod.props.name)
      if decorate and mod_config.enabled then
        local ok, chunks =
          pcall(decorate, row, prefix_col, build_mod_context(mod_config))
        if ok and chunks then return chunks end
      end
    end
    return build_blank_prefix(line_at, row, prefix_col)
  end
end

return line_prefix_decorator
