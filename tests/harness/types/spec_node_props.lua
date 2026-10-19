---@meta

---@class SpecNodeProps
---@field name? string
---@field parent? SpecNodeProps
---@field children SpecNodeProps[]
---@field before_each (fun())[]
---@field after_each (fun())[]
---@field body fun()
