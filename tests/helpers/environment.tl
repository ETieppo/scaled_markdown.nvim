local MISSING_REASON_FORMAT <const> = "requires executables: %s"
local NAME_SEPARATOR <const> = ", "

local record environment
end

function environment.has_executable(name: string): boolean
    return vim.fn.executable(name) == 1
end

function environment.has_executables(names: {string}): boolean
    for _, name in ipairs(names) do
        if not environment.has_executable(name) then
            return false
        end
    end
    return true
end

function environment.missing_reason(names: {string}): string
    return MISSING_REASON_FORMAT:format(table.concat(names, NAME_SEPARATOR))
end

return environment
