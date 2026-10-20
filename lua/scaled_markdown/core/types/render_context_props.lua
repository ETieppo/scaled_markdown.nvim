---@meta

---@class RenderContextProps<C>
---@field buf integer
---@field win integer
---@field writer ExtmarkWriterProps
---@field text_area_width integer
---@field line_at fun(row: integer): string
---@field decorate_line_prefix fun(row: integer, prefix_col: integer): [string, string][]
---@field mod_config C
