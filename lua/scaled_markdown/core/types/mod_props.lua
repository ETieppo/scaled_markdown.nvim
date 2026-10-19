---@meta

---@class ModProps
---@field name string
---@field language LanguageEnum
---@field query string
---@field default_config ModConfigProps
---@field highlights? HighlightDefinitionsProps|(fun(): HighlightDefinitionsProps)
---@field render fun(capture_dto: CaptureProps, context_dto: RenderContextProps<ModConfigProps>)
