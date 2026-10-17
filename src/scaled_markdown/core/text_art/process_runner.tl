local FAILED_PROCESS_RESULT <const>: vim.SystemCompletedProps =
  { code = -1, stdout = nil, stderr = nil }

local record process_runner
end

function process_runner.run_async(
  command: {string},
  process_options: vim.SystemOptionsProps,
  on_exit: function(vim.SystemCompletedProps)
)
  local ok = pcall(vim.system, command, process_options, on_exit)
  if not ok then on_exit(FAILED_PROCESS_RESULT) end
end

function process_runner.run_sync(
  command: {string},
  process_options: vim.SystemOptionsProps,
  timeout_ms: integer
): vim.SystemCompletedProps
  local ok, process = pcall(vim.system, command, process_options)
  if not ok then return FAILED_PROCESS_RESULT end
  return process:wait(timeout_ms)
end

return process_runner
