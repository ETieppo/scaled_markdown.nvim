local type SpecNodeProps = require("harness.types.spec_node_props")
local type SpecResultProps = require("harness.types.spec_result_props")
local SPEC_STATUS_ENUM = require("harness.spec_status_enum")
local type SpecStatusEnum = SPEC_STATUS_ENUM.SpecStatusEnum
local notify_capture = require("harness.notify_capture")
local stub = require("harness.stub")

local NAME_SEPARATOR <const> = " › "
local SPEC_FRAME_MARKER <const> = "/specs/"
local FRAME_SEPARATOR <const> = "\n      at "
local NOTIFICATION_SEPARATOR <const> = "\n      "
local UNEXPECTED_ERRORS_HEADER <const> = "unexpected error notifications:"
local NANOSECONDS_PER_MILLISECOND <const> = 1e6
local SKIP_SIGNAL <const>: {string: boolean} = {}

local type HookListProps = {function()}

local record spec
end

local function new_node(name: string, parent: SpecNodeProps): SpecNodeProps
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
local skip_reason: string = nil

function spec.describe(name: string, body: function())
    local group_node = new_node(name, current_node)
    table.insert(current_node.children, group_node)
    local parent_node = current_node
    current_node = group_node
    body()
    current_node = parent_node
end

function spec.it(name: string, body: function())
    local test_node = new_node(name, current_node)
    test_node.body = body
    table.insert(current_node.children, test_node)
end

function spec.before_each(hook: function())
    table.insert(current_node.before_each, hook)
end

function spec.after_each(hook: function())
    table.insert(current_node.after_each, hook)
end

function spec.skip(reason: string)
    skip_reason = reason
    error(SKIP_SIGNAL, 0)
end

function spec.skip_unless(condition: boolean, reason: string)
    if not condition then
        spec.skip(reason)
    end
end

local function collect_hooks(
    group_node: SpecNodeProps, select_hooks: function(SpecNodeProps): HookListProps
): HookListProps
    local chain: {SpecNodeProps} = {}
    local cursor = group_node
    while cursor do
        table.insert(chain, 1, cursor)
        cursor = cursor.parent
    end
    local hooks: HookListProps = {}
    for _, chain_node in ipairs(chain) do
        vim.list_extend(hooks, select_hooks(chain_node))
    end
    return hooks
end

local function select_before_each(node: SpecNodeProps): HookListProps
    return node.before_each
end

local function select_after_each(node: SpecNodeProps): HookListProps
    return node.after_each
end

local function build_full_name(test_node: SpecNodeProps): string
    local parts: {string} = {}
    local cursor = test_node
    while cursor and cursor.name do
        table.insert(parts, 1, cursor.name)
        cursor = cursor.parent
    end
    return table.concat(parts, NAME_SEPARATOR)
end

local function reset_editor()
    stub.restore_all()
    vim.cmd("silent! only!")
    vim.cmd("silent! enew!")
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if buf ~= vim.api.nvim_get_current_buf() then
            pcall(vim.api.nvim_buf_delete, buf, {force = true})
        end
    end
end

local function keep_spec_frames(traceback: string): {string}
    local kept: {string} = {}
    for line in traceback:gmatch("[^\n]+") do
        if line:find(SPEC_FRAME_MARKER, 1, true) then
            kept[#kept + 1] = vim.trim(line)
        end
    end
    return kept
end

local function handle_error(error_message: any): any
    if error_message == SKIP_SIGNAL then
        return SKIP_SIGNAL
    end
    local frames = keep_spec_frames(debug.traceback("", 2))
    return table.concat(
        vim.list_extend({tostring(error_message)}, frames), FRAME_SEPARATOR
    )
end

local function run_hooks(hooks: HookListProps)
    for _, hook in ipairs(hooks) do
        hook()
    end
end

local function resolve_outcome(
    body_ok: boolean,
    body_error: any,
    after_ok: boolean,
    after_error: any,
    unexpected_errors: {string}
): SpecStatusEnum, string
    if body_error == SKIP_SIGNAL then
        return SPEC_STATUS_ENUM.SKIPPED, skip_reason
    end
    if not body_ok then
        return SPEC_STATUS_ENUM.FAILED, tostring(body_error)
    end
    if not after_ok then
        return SPEC_STATUS_ENUM.FAILED, tostring(after_error)
    end
    if #unexpected_errors > 0 then
        return SPEC_STATUS_ENUM.FAILED,
            UNEXPECTED_ERRORS_HEADER
                .. NOTIFICATION_SEPARATOR
                .. table.concat(unexpected_errors, NOTIFICATION_SEPARATOR)
    end
    return SPEC_STATUS_ENUM.PASSED, nil
end

local function run_test(test_node: SpecNodeProps, results: {SpecResultProps})
    skip_reason = nil
    notify_capture.reset()
    local started_at = vim.uv.hrtime()
    local group_node = test_node.parent
    local body_ok, body_error: boolean, any = xpcall(
        function()
            run_hooks(collect_hooks(group_node, select_before_each))
            test_node.body()
        end,
        handle_error
    )
    local after_ok, after_error: boolean, any = xpcall(
        function() run_hooks(collect_hooks(group_node, select_after_each)) end,
        handle_error
    )
    local unexpected_errors = notify_capture.take_errors()
    reset_editor()

    local status, message = resolve_outcome(
        body_ok, body_error, after_ok, after_error, unexpected_errors
    )
    results[#results + 1] = {
        name = build_full_name(test_node),
        status = status,
        message = message,
        duration_ms = (vim.uv.hrtime() - started_at) / NANOSECONDS_PER_MILLISECOND,
    }
end

local function run_node(node: SpecNodeProps, results: {SpecResultProps})
    for _, child_node in ipairs(node.children) do
        if child_node.body then
            run_test(child_node, results)
        else
            run_node(child_node, results)
        end
    end
end

function spec.run(): {SpecResultProps}
    local results: {SpecResultProps} = {}
    run_node(root_node, results)
    return results
end

return spec
