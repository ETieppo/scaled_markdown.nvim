---@alias CodeBlockCaptureEnum 'fenced_code_block'|'indented_code_block'

---@class CodeBlockCaptureEnumProps
---@field FENCED CodeBlockCaptureEnum
---@field INDENTED CodeBlockCaptureEnum

---@type CodeBlockCaptureEnumProps
local CODE_BLOCK_CAPTURE_ENUM = {
  FENCED = 'fenced_code_block',
  INDENTED = 'indented_code_block',
}

return CODE_BLOCK_CAPTURE_ENUM
