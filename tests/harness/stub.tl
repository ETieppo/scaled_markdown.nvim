local type CallArgumentsProps = {any}
local type VariadicFunctionProps = function(...: any): any...

local record ReplacedEntryProps
    target: {string: any}
    key: string
    original: any
end

local record stub
end

local replaced_entries: {ReplacedEntryProps} = {}

function stub.replace(target: any, key: string, value: any)
    local fields = target as {string: any}
    replaced_entries[#replaced_entries + 1] = {
        target = fields, key = key, original = rawget(fields, key)
    }
    rawset(fields, key, value)
end

function stub.spy(target: any, key: string): {CallArgumentsProps}
    local calls: {CallArgumentsProps} = {}
    local original = (target as {string: any})[key] as VariadicFunctionProps
    stub.replace(
        target,
        key,
        function(...: any): any... calls[#calls + 1] = {...}; return original(...) end
    )
    return calls
end

function stub.restore_all()
    for index = #replaced_entries, 1, -1 do
        local entry = replaced_entries[index]
        rawset(entry.target, entry.key, entry.original)
    end
    replaced_entries = {}
end

return stub
