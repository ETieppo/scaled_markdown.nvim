local record CapturedMessageProps
    message: string
    level: integer
end

local record notify_capture
end

local captured_messages: {CapturedMessageProps} = {}

function notify_capture.install()
    vim.notify = function(message: string, level?: integer)
        captured_messages[#captured_messages + 1] = {
            message = tostring(message), level = level or vim.log.levels.INFO
        }
    end
end

function notify_capture.take(level?: integer): {string}
    local taken: {string} = {}
    local kept: {CapturedMessageProps} = {}
    for _, entry in ipairs(captured_messages) do
        if level == nil or entry.level == level then
            taken[#taken + 1] = entry.message
        else
            kept[#kept + 1] = entry
        end
    end
    captured_messages = kept
    return taken
end

function notify_capture.take_errors(): {string}
    return notify_capture.take(vim.log.levels.ERROR)
end

function notify_capture.reset()
    captured_messages = {}
end

return notify_capture
