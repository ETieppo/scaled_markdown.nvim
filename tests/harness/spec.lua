local SPEC_STATUS_ENUM = require 'harness.spec_status_enum'
local notify_capture = require 'harness.notify_capture'
local stub = require 'harness.stub'

local NAME_SEPARATOR = ' › '
local SPEC_FRAME_MARKER = '/specs/'
local FRAME_SEPARATOR = '\n      at '
local NOTIFICATION_SEPARATOR = '\n      '
local UNEXPECTED_ERRORS_HEADER = 'unexpected error notifications:'
local NANOSECONDS_PER_MILLISECOND = 1e6
---@type table<string, boolean>
local SKIP_SIGNAL = {}

---@alias HookListProps (fun())[]

---@class spec
local spec = {}

---@param name? string
---@param parent? SpecNodeProps
---@return SpecNodeProps
local function new_node(name, parent)
  return {
    name = name,
    parent = parent,
    children = {},
    before_each = {},
    after_each = {},
  }
end

local root_node = new_node(nil, nil)
local current_node = root_node
---@type string?
local skip_reason = nil

---@param name string
---@param body fun()
function spec.describe(name, body)
  local group_node = new_node(name, current_node)
  table.insert(current_node.children, group_node)
  local parent_node = current_node
  current_node = group_node
  body()
  current_node = parent_node
end

---@param name string
---@param body fun()
function spec.it(name, body)
  local test_node = new_node(name, current_node)
  test_node.body = body
  table.insert(current_node.children, test_node)
end

---@param hook fun()
function spec.before_each(hook) table.insert(current_node.before_each, hook) end

---@param hook fun()
function spec.after_each(hook) table.insert(current_node.after_each, hook) end

---@param reason string
function spec.skip(reason)
  skip_reason = reason
  error(SKIP_SIGNAL, 0)
end

---@param condition boolean
---@param reason string
function spec.skip_unless(condition, reason)
  if not condition then spec.skip(reason) end
end

---@param group_node? SpecNodeProps
---@param select_hooks fun(node: SpecNodeProps): HookListProps
---@return HookListProps
local function collect_hooks(group_node, select_hooks)
  ---@type SpecNodeProps[]
  local chain = {}
  local cursor = group_node
  while cursor do
    table.insert(chain, 1, cursor)
    cursor = cursor.parent
  end
  ---@type HookListProps
  local hooks = {}
  for _, chain_node in ipairs(chain) do
    vim.list_extend(hooks, select_hooks(chain_node))
  end
  return hooks
end

---@param node SpecNodeProps
---@return HookListProps
local function select_before_each(node) return node.before_each end

---@param node SpecNodeProps
---@return HookListProps
local function select_after_each(node) return node.after_each end

---@param test_node SpecNodeProps
---@return string
local function build_full_name(test_node)
  ---@type string[]
  local parts = {}
  local cursor = test_node
  while cursor and cursor.name do
    table.insert(parts, 1, cursor.name)
    cursor = cursor.parent
  end
  return table.concat(parts, NAME_SEPARATOR)
end

local function reset_editor()
  stub.restore_all()
  vim.cmd 'silent! only!'
  vim.cmd 'silent! enew!'
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= vim.api.nvim_get_current_buf() then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end
end

---@param traceback string
---@return string[]
local function keep_spec_frames(traceback)
  ---@type string[]
  local kept = {}
  for line in traceback:gmatch '[^\n]+' do
    if line:find(SPEC_FRAME_MARKER, 1, true) then
      kept[#kept + 1] = vim.trim(line)
    end
  end
  return kept
end

---@param error_message any
---@return any
local function handle_error(error_message)
  if error_message == SKIP_SIGNAL then return SKIP_SIGNAL end
  local frames = keep_spec_frames(debug.traceback('', 2))
  return table.concat(
    vim.list_extend({ tostring(error_message) }, frames),
    FRAME_SEPARATOR
  )
end

---@param hooks HookListProps
local function run_hooks(hooks)
  for _, hook in ipairs(hooks) do
    hook()
  end
end

---@param body_ok boolean
---@param body_error any
---@param after_ok boolean
---@param after_error any
---@param unexpected_errors string[]
---@return SpecStatusEnum
---@return string?
local function resolve_outcome(
  body_ok,
  body_error,
  after_ok,
  after_error,
  unexpected_errors
)
  if body_error == SKIP_SIGNAL then
    return SPEC_STATUS_ENUM.SKIPPED, skip_reason
  end
  if not body_ok then return SPEC_STATUS_ENUM.FAILED, tostring(body_error) end
  if not after_ok then return SPEC_STATUS_ENUM.FAILED, tostring(after_error) end
  if #unexpected_errors > 0 then
    return SPEC_STATUS_ENUM.FAILED,
      UNEXPECTED_ERRORS_HEADER .. NOTIFICATION_SEPARATOR .. table.concat(
        unexpected_errors,
        NOTIFICATION_SEPARATOR
      )
  end
  return SPEC_STATUS_ENUM.PASSED, nil
end

---@param test_node SpecNodeProps
---@param results SpecResultProps[]
local function run_test(test_node, results)
  skip_reason = nil
  notify_capture.reset()
  local started_at = vim.uv.hrtime()
  local group_node = test_node.parent
  ---@type boolean, any
  local body_ok, body_error = xpcall(function()
    run_hooks(collect_hooks(group_node, select_before_each))
    test_node.body()
  end, handle_error)
  ---@type boolean, any
  local after_ok, after_error = xpcall(
    function() run_hooks(collect_hooks(group_node, select_after_each)) end,
    handle_error
  )
  local unexpected_errors = notify_capture.take_errors()
  reset_editor()

  local status, message = resolve_outcome(
    body_ok,
    body_error,
    after_ok,
    after_error,
    unexpected_errors
  )
  results[#results + 1] = {
    name = build_full_name(test_node),
    status = status,
    message = message,
    duration_ms = (vim.uv.hrtime() - started_at) / NANOSECONDS_PER_MILLISECOND,
  }
end

---@param node SpecNodeProps
---@param results SpecResultProps[]
local function run_node(node, results)
  for _, child_node in ipairs(node.children) do
    if child_node.body then
      run_test(child_node, results)
    else
      run_node(child_node, results)
    end
  end
end

---@return SpecResultProps[]
function spec.run()
  ---@type SpecResultProps[]
  local results = {}
  run_node(root_node, results)
  return results
end

return spec
