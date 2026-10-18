local FAILED_PROCESS_RESULT =
{ code = -1, stdout = nil, stderr = nil }

local process_runner = {}


function process_runner.run_async(
   command,
   process_options,
   on_exit)

   local ok = pcall(vim.system, command, process_options, on_exit)
   if not ok then on_exit(FAILED_PROCESS_RESULT) end
end

function process_runner.run_sync(
   command,
   process_options,
   timeout_ms)

   local ok, process = pcall(vim.system, command, process_options)
   if not ok then return FAILED_PROCESS_RESULT end
   return process:wait(timeout_ms)
end

return process_runner
