local SCRIPT_FLAG = '-l'

---@class script_arguments
local script_arguments = {}

---@return string[]
function script_arguments.read()
  local argv = vim.v.argv
  for index, argument in ipairs(argv) do
    if argument == SCRIPT_FLAG then
      return vim.list_slice(argv, index + 2, #argv)
    end
  end
  return {}
end

return script_arguments
