---@meta

---@class ModProps
---@field name string
---@field language LanguageEnum
---@field query string
---@field default_config ModConfigProps
---@field highlights? HighlightDefinitionsProps|(fun(): HighlightDefinitionsProps)
---@field render fun(capture_dto: CaptureProps, context_dto: RenderContextProps<ModConfigProps>)
---@field decorate_line_prefix? fun(row: integer, prefix_col: integer, context_dto: RenderContextProps<ModConfigProps>): [string, string][]?
