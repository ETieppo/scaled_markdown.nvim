---@meta

---@class PillCapsProps
---@field left string
---@field right string

---@class StyleProps
---@field font? string
---@field symbols? string
---@field rows_by_level? integer[]
---@field line_height_cells_by_level? number[]
---@field fonts_by_level? string[]

---@class HeadingConfigProps: ModConfigProps
---@field icons_by_level string[]
---@field pill_caps PillCapsProps
---@field line_styles_by_level HeadingLineStyleEnum[]
---@field styles table<RendererEnum, StyleProps>
