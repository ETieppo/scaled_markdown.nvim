local ESCAPE = '\27'
local DOUBLED_ESCAPE = '\27\27'
local PASSTHROUGH_START = '\27Ptmux;'
local PASSTHROUGH_END = '\27\\'

---@class tmux_passthrough
local tmux_passthrough = {}

---@param sequence string
---@return string
function tmux_passthrough.wrap(sequence)
  local escaped_sequence = sequence:gsub(ESCAPE, DOUBLED_ESCAPE)
  return PASSTHROUGH_START .. escaped_sequence .. PASSTHROUGH_END
end

return tmux_passthrough
