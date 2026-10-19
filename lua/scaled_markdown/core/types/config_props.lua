---@meta

---@class RevealProps
---@field cursor_line? boolean
---@field visual_selection? boolean

---@class GradientProps
---@field steps? integer
---@field colors? string|string[]
---@field fill_foreground? string

---@class TerminalProps
---@field cell_width_pixels? integer
---@field cell_height_pixels? integer
---@field fallback_cell_width_pixels? integer
---@field fallback_cell_height_pixels? integer

---@class ConfigProps
---@field enabled? boolean
---@field file_types? string[]
---@field renderer? RendererEnum
---@field reveal? RevealProps
---@field window_options? WindowOptionsProps
---@field gradient? GradientProps
---@field terminal? TerminalProps
---@field mods? table<string, ModConfigProps>
