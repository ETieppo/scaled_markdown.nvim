local type SpecResultProps = require("harness.types.spec_result_props")
local SPEC_STATUS_ENUM = require("harness.spec_status_enum")
local type SpecStatusEnum = SPEC_STATUS_ENUM.SpecStatusEnum
local reporter = require("harness.reporter")
local script_arguments = require("harness.script_arguments")

local SPEC_FILE_PATTERN <const> = "_spec%.lua$"
local COMPILED_EXTENSION_PATTERN <const> = "%.lua$"
local SOURCE_EXTENSION <const> = ".tl"
local SOURCE_TESTS_DIRECTORY <const> = "tests"
local SPECS_DIRECTORY <const> = "/specs"
local BOOTSTRAP_RELATIVE_PATH <const> = "/harness/child_bootstrap.lua"
local PARSER_SITE_PATH <const> = vim.fn.stdpath("data") .. "/site"
local RUNTIME_PATH_COMMAND_FORMAT <const> = "set rtp^=%s,%s"
local PACKAGE_PATH_COMMAND_FORMAT <const> = "lua package.path = '%s/?.lua;' .. package.path"
local SPEC_TIMEOUT_MS <const> = 60000
local TIMEOUT_EXIT_CODE <const> = 124
local CRASH_TEST_NAME <const> = "<spec process crashed>"
local TIMEOUT_MESSAGE_FORMAT <const> = "spec process timed out after %d ms (possible hang)"
local CRASH_MESSAGE_FORMAT <const> = "exit code %d\n%s"
local READ_ALL_MODE <const> = "*a"
local NANOSECONDS_PER_SECOND <const> = 1e9

local arguments = script_arguments.read()
local repo_root = arguments[1]
local plugin_build_root = arguments[2]
local tests_build_root = arguments[3]
local filters = vim.list_slice(arguments, 4, #arguments)
local max_parallel_specs = math.max(1, #vim.uv.cpu_info())

local function matches_filters(spec_path: string): boolean
    if #filters == 0 then
        return true
    end
    for _, filter in ipairs(filters) do
        if spec_path:find(filter, 1, true) then
            return true
        end
    end
    return false
end

local function discover_specs(): {string}
    local spec_paths = vim.fs.find(
        function(name: string): boolean
            return name:match(SPEC_FILE_PATTERN) ~= nil
        end,
        {path = tests_build_root .. SPECS_DIRECTORY, type = "file", limit = math.huge}
    )
    table.sort(spec_paths)
    return vim.tbl_filter(matches_filters, spec_paths)
end

local function to_source_path(spec_path: string): string
    local relative_path = spec_path:sub(#tests_build_root + 1)
    return (
        SOURCE_TESTS_DIRECTORY
        .. relative_path:gsub(COMPILED_EXTENSION_PATTERN, SOURCE_EXTENSION)
    )
end

local function build_child_command(spec_path: string, results_path: string): {string}
    return {
        vim.v.progpath,
        "--clean",
        "--headless",
        "--cmd",
        RUNTIME_PATH_COMMAND_FORMAT:format(plugin_build_root, PARSER_SITE_PATH),
        "--cmd",
        PACKAGE_PATH_COMMAND_FORMAT:format(tests_build_root),
        "-l",
        tests_build_root .. BOOTSTRAP_RELATIVE_PATH,
        spec_path,
        results_path,
    }
end

local function read_results(
    results_path: string, process_result: vim.SystemCompletedProps
): {SpecResultProps}
    local file = io.open(results_path, "r")
    if file then
        local content = file:read(READ_ALL_MODE)
        file:close()
        os.remove(results_path)
        return vim.json.decode(content) as {SpecResultProps}
    end
    local message = process_result.code == TIMEOUT_EXIT_CODE
        and TIMEOUT_MESSAGE_FORMAT:format(
            SPEC_TIMEOUT_MS
        ) or CRASH_MESSAGE_FORMAT:format(
        process_result.code,
        (process_result.stdout or "") .. (process_result.stderr or "")
    )
    return {
        {name = CRASH_TEST_NAME, status = SPEC_STATUS_ENUM.FAILED, message = message},
    }
end

local function run_specs(spec_paths: {string}): {string: {SpecResultProps}}
    local results_by_spec: {string: {SpecResultProps}} = {}
    local next_index, running_count = 1, 0

    local function start_next()
        if next_index > #spec_paths then
            return
        end
        local spec_path = spec_paths[next_index]
        next_index = next_index + 1
        running_count = running_count + 1

        local results_path = vim.fn.tempname()
        vim.system(
            build_child_command(spec_path, results_path),
            {cwd = repo_root, text = true, timeout = SPEC_TIMEOUT_MS},
            function(process_result: vim.SystemCompletedProps)
                vim.schedule(
                    function()
                        results_by_spec[spec_path] = read_results(
                            results_path, process_result
                        )
                        running_count = running_count - 1
                        start_next()
                    end
                )
            end
        )
    end

    for _ = 1, math.min(max_parallel_specs, #spec_paths) do
        start_next()
    end

    vim.wait(
        SPEC_TIMEOUT_MS * #spec_paths,
        function(): boolean return running_count == 0 and next_index > #spec_paths end
    )
    return results_by_spec
end

local function report(
    spec_paths: {string}, results_by_spec: {string: {SpecResultProps}}
): {SpecStatusEnum: integer}
    local totals: {SpecStatusEnum: integer} = {
        [SPEC_STATUS_ENUM.PASSED] = 0,
        [SPEC_STATUS_ENUM.FAILED] = 0,
        [SPEC_STATUS_ENUM.SKIPPED] = 0,
    }

    for _, spec_path in ipairs(spec_paths) do
        local results = results_by_spec[spec_path] or {}
        reporter.spec_file(to_source_path(spec_path), results)

        for _, result in ipairs(results) do
            totals[result.status] = totals[result.status] + 1
        end
    end
    return totals
end

local started_at = vim.uv.hrtime()
local spec_paths = discover_specs()
if #spec_paths == 0 then
    reporter.no_specs(filters)
    os.exit(1)
end

local totals = report(spec_paths, run_specs(spec_paths))
reporter.summary(
    totals, #spec_paths, (vim.uv.hrtime() - started_at) / NANOSECONDS_PER_SECOND
)
os.exit(totals[SPEC_STATUS_ENUM.FAILED] > 0 and 1 or 0)
