local SCRIPT_FLAG <const> = "-l"

local record script_arguments
end

function script_arguments.read(): {string}
    local argv = vim.v.argv
    for index, argument in ipairs(argv) do
        if argument == SCRIPT_FLAG then
            return vim.list_slice(argv, index + 2, #argv)
        end
    end
    return {}
end

return script_arguments
