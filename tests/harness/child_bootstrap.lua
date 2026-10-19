local SPEC_STATUS_ENUM = require 'harness.spec_status_enum'
local notify_capture = require 'harness.notify_capture'
local script_arguments = require 'harness.script_arguments'
local spec = require 'harness.spec'

local LOAD_FAILURE_NAME = '<spec file failed to load>'
local WRITE_MODE = 'w'

local arguments = script_arguments.read()
local spec_path = arguments[1]
local results_path = arguments[2]

---@param results SpecResultProps[]
local function write_results(results)
  local file = assert(io.open(results_path, WRITE_MODE))
  file:write(vim.json.encode(results))
  file:close()
end

---@param error_message any
---@return any
local function format_load_error(error_message)
  return debug.traceback(tostring(error_message), 2)
end

notify_capture.install()

---@type boolean, any
local load_ok, load_error = xpcall(
  function() dofile(spec_path) end,
  format_load_error
)

if load_ok then
  write_results(spec.run())
else
  write_results {
    {
      name = LOAD_FAILURE_NAME,
      status = SPEC_STATUS_ENUM.FAILED,
      message = tostring(load_error),
    },
  }
end

vim.cmd 'qall!'
