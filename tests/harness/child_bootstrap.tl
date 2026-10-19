local type SpecResultProps = require("harness.types.spec_result_props")
local SPEC_STATUS_ENUM = require("harness.spec_status_enum")
local notify_capture = require("harness.notify_capture")
local script_arguments = require("harness.script_arguments")
local spec = require("harness.spec")

local LOAD_FAILURE_NAME <const> = "<spec file failed to load>"
local WRITE_MODE <const> = "w"

local arguments = script_arguments.read()
local spec_path = arguments[1]
local results_path = arguments[2]

local function write_results(results: {SpecResultProps})
    local file = assert(io.open(results_path, WRITE_MODE))
    file:write(vim.json.encode(results))
    file:close()
end

local function format_load_error(error_message: any): any
    return debug.traceback(tostring(error_message), 2)
end

notify_capture.install()

local load_ok, load_error: boolean, any = xpcall(
    function() dofile(spec_path) end, format_load_error
)

if load_ok then
    write_results(spec.run())
else
    write_results(
        {
            {
                name = LOAD_FAILURE_NAME,
                status = SPEC_STATUS_ENUM.FAILED,
                message = tostring(load_error),
            },
        }
    )
end

vim.cmd("qall!")
