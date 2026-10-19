local PLACEHOLDER_CODEPOINT = 0x10EEEE
---@type integer[]
local ROW_DIACRITIC_CODEPOINTS = {
  0x0305,
  0x030D,
  0x030E,
  0x0310,
  0x0312,
  0x033D,
  0x033E,
  0x033F,
  0x0346,
  0x034A,
  0x034B,
  0x034C,
  0x0350,
  0x0351,
  0x0352,
  0x0357,
  0x035B,
  0x0363,
  0x0364,
  0x0365,
  0x0366,
  0x0367,
  0x0368,
  0x0369,
  0x036A,
  0x036B,
  0x036C,
  0x036D,
  0x036E,
  0x036F,
  0x0483,
  0x0484,
}

---@class graphics_placeholder_builder
local graphics_placeholder_builder = {}

---@return integer
function graphics_placeholder_builder.max_rows()
  return #ROW_DIACRITIC_CODEPOINTS
end

---@param columns integer
---@param rows integer
---@return string[]
function graphics_placeholder_builder.build_lines(columns, rows)
  local placeholder = vim.fn.nr2char(PLACEHOLDER_CODEPOINT)
  local trailing_cells = string.rep(placeholder, columns - 1)
  ---@type string[]
  local lines = {}
  for row_index = 1, math.min(rows, #ROW_DIACRITIC_CODEPOINTS) do
    local row_diacritic = vim.fn.nr2char(ROW_DIACRITIC_CODEPOINTS[row_index])
    lines[row_index] = placeholder .. row_diacritic .. trailing_cells
  end
  return lines
end

return graphics_placeholder_builder
