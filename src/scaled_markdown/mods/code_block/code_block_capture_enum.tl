local enum CodeBlockCaptureEnum
  'fenced_code_block'
  'indented_code_block'
end

local record CodeBlockCaptureEnumProps
  type CodeBlockCaptureEnum = CodeBlockCaptureEnum

  FENCED: CodeBlockCaptureEnum
  INDENTED: CodeBlockCaptureEnum
end

local CODE_BLOCK_CAPTURE_ENUM <const>: CodeBlockCaptureEnumProps = {
  FENCED = 'fenced_code_block',
  INDENTED = 'indented_code_block',
}

return CODE_BLOCK_CAPTURE_ENUM
