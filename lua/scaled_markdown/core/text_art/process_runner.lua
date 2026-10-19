---@type vim.SystemCompleted
local FAILED_PROCESS_RESULT =
  { code = -1, signal = 0, stdout = nil, stderr = nil }

---@class process_runner
local process_runner = {}

---@param command string[]
---@param process_options vim.SystemOpts
---@param on_exit fun(result: vim.SystemCompleted)
function process_runner.run_async(command, process_options, on_exit)
  local ok = pcall(vim.system, command, process_options, on_exit)
  if not ok then on_exit(FAILED_PROCESS_RESULT) end
end

---@param command string[]
---@param process_options vim.SystemOpts
---@param timeout_ms integer
---@return vim.SystemCompleted
function process_runner.run_sync(command, process_options, timeout_ms)
  local ok, process = pcall(vim.system, command, process_options)
  if not ok then return FAILED_PROCESS_RESULT end
  return process:wait(timeout_ms)
end

return process_runner
