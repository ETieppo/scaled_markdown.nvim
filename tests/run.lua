local SPEC_STATUS_ENUM = require 'harness.spec_status_enum'
local reporter = require 'harness.reporter'
local script_arguments = require 'harness.script_arguments'

local SPEC_FILE_PATTERN = '_spec%.lua$'
local TESTS_DIRECTORY = 'tests'
local SPECS_DIRECTORY = '/specs'
local BOOTSTRAP_RELATIVE_PATH = '/harness/child_bootstrap.lua'
local PARSER_SITE_PATH = vim.fn.stdpath 'data' .. '/site'
local RUNTIME_PATH_COMMAND_FORMAT = 'set rtp^=%s,%s'
local PACKAGE_PATH_COMMAND_FORMAT =
  "lua package.path = '%s/?.lua;' .. package.path"
local SPEC_TIMEOUT_MS = 60000
local TIMEOUT_EXIT_CODE = 124
local CRASH_TEST_NAME = '<spec process crashed>'
local TIMEOUT_MESSAGE_FORMAT =
  'spec process timed out after %d ms (possible hang)'
local CRASH_MESSAGE_FORMAT = 'exit code %d\n%s'
local READ_ALL_MODE = '*a'
local NANOSECONDS_PER_SECOND = 1e9

local arguments = script_arguments.read()
local repo_root = arguments[1]
local tests_root = arguments[2]
local filters = vim.list_slice(arguments, 3, #arguments)
local max_parallel_specs = math.max(1, #vim.uv.cpu_info())

---@param spec_path string
---@return boolean
local function matches_filters(spec_path)
  if #filters == 0 then return true end
  for _, filter in ipairs(filters) do
    if spec_path:find(filter, 1, true) then return true end
  end
  return false
end

---@return string[]
local function discover_specs()
  local spec_paths = vim.fs.find(
    ---@param name string
    ---@return boolean
    function(name) return name:match(SPEC_FILE_PATTERN) ~= nil end,
    {
      path = tests_root .. SPECS_DIRECTORY,
      type = 'file',
      limit = math.huge,
    }
  )
  table.sort(spec_paths)
  return vim.tbl_filter(matches_filters, spec_paths)
end

---@param spec_path string
---@return string
local function to_display_path(spec_path)
  return TESTS_DIRECTORY .. spec_path:sub(#tests_root + 1)
end

---@param spec_path string
---@param results_path string
---@return string[]
local function build_child_command(spec_path, results_path)
  return {
    vim.v.progpath,
    '--clean',
    '--headless',
    '--cmd',
    RUNTIME_PATH_COMMAND_FORMAT:format(repo_root, PARSER_SITE_PATH),
    '--cmd',
    PACKAGE_PATH_COMMAND_FORMAT:format(tests_root),
    '-l',
    tests_root .. BOOTSTRAP_RELATIVE_PATH,
    spec_path,
    results_path,
  }
end

---@param results_path string
---@param process_result vim.SystemCompleted
---@return SpecResultProps[]
local function read_results(results_path, process_result)
  local file = io.open(results_path, 'r')
  if file then
    local content = file:read(READ_ALL_MODE)
    file:close()
    os.remove(results_path)
    return vim.json.decode(content)
  end
  local message = process_result.code == TIMEOUT_EXIT_CODE
      and TIMEOUT_MESSAGE_FORMAT:format(SPEC_TIMEOUT_MS)
    or CRASH_MESSAGE_FORMAT:format(
      process_result.code,
      (process_result.stdout or '') .. (process_result.stderr or '')
    )
  return {
    {
      name = CRASH_TEST_NAME,
      status = SPEC_STATUS_ENUM.FAILED,
      message = message,
    },
  }
end

---@param spec_paths string[]
---@return table<string, SpecResultProps[]>
local function run_specs(spec_paths)
  ---@type table<string, SpecResultProps[]>
  local results_by_spec = {}
  local next_index, running_count = 1, 0

  local function start_next()
    if next_index > #spec_paths then return end
    local spec_path = spec_paths[next_index]
    next_index = next_index + 1
    running_count = running_count + 1

    local results_path = vim.fn.tempname()
    vim.system(
      build_child_command(spec_path, results_path),
      { cwd = repo_root, text = true, timeout = SPEC_TIMEOUT_MS },
      ---@param process_result vim.SystemCompleted
      function(process_result)
        vim.schedule(function()
          results_by_spec[spec_path] =
            read_results(results_path, process_result)
          running_count = running_count - 1
          start_next()
        end)
      end
    )
  end

  for _ = 1, math.min(max_parallel_specs, #spec_paths) do
    start_next()
  end

  vim.wait(
    SPEC_TIMEOUT_MS * #spec_paths,
    ---@return boolean
    function() return running_count == 0 and next_index > #spec_paths end
  )
  return results_by_spec
end

---@param spec_paths string[]
---@param results_by_spec table<string, SpecResultProps[]>
---@return table<SpecStatusEnum, integer>
local function report(spec_paths, results_by_spec)
  ---@type table<SpecStatusEnum, integer>
  local totals = {
    [SPEC_STATUS_ENUM.PASSED] = 0,
    [SPEC_STATUS_ENUM.FAILED] = 0,
    [SPEC_STATUS_ENUM.SKIPPED] = 0,
  }

  for _, spec_path in ipairs(spec_paths) do
    local results = results_by_spec[spec_path] or {}
    reporter.spec_file(to_display_path(spec_path), results)

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
  totals,
  #spec_paths,
  (vim.uv.hrtime() - started_at) / NANOSECONDS_PER_SECOND
)
os.exit(totals[SPEC_STATUS_ENUM.FAILED] > 0 and 1 or 0)
