local ERROR_LEVEL <const> = 3

local record assertions
end

local function describe_value(value: any): string
    return vim.inspect(value)
end

local function raise(description: string, detail: string)
    error(("%s\n      %s"):format(description, detail), ERROR_LEVEL)
end

function assertions.equal(actual: any, expected: any, description: string)
    if actual ~= expected then
        raise(
            description,
            ("expected %s, got %s"):format(
                describe_value(expected), describe_value(actual)
            )
        )
    end
end

function assertions.not_equal(actual: any, unexpected: any, description: string)
    if actual == unexpected then
        raise(description, ("expected anything but %s"):format(describe_value(actual)))
    end
end

function assertions.deep_equal(actual: any, expected: any, description: string)
    if not vim.deep_equal(actual, expected) then
        raise(
            description,
            ("expected %s, got %s"):format(
                describe_value(expected), describe_value(actual)
            )
        )
    end
end

function assertions.truthy(value: any, description: string)
    if not value then
        raise(description, ("expected truthy, got %s"):format(describe_value(value)))
    end
end

function assertions.falsy(value: any, description: string)
    if value then
        raise(description, ("expected falsy, got %s"):format(describe_value(value)))
    end
end

function assertions.is_nil(value: any, description: string)
    if value ~= nil then
        raise(description, ("expected nil, got %s"):format(describe_value(value)))
    end
end

function assertions.at_least(actual: number, minimum: number, description: string)
    if actual == nil or actual < minimum then
        raise(
            description,
            ("expected >= %s, got %s"):format(tostring(minimum), describe_value(actual))
        )
    end
end

function assertions.matches(text: string, pattern: string, description: string)
    if text == nil or not text:find(pattern) then
        raise(
            description,
            ("expected %s to match %s"):format(describe_value(text), pattern)
        )
    end
end

function assertions.contains(list: {any}, item: any, description: string)
    local is_found = false
    for _, candidate in ipairs(list or {}) do
        is_found = is_found or vim.deep_equal(candidate, item)
    end
    if not is_found then
        raise(
            description,
            ("expected %s to contain %s"):format(
                describe_value(list), describe_value(item)
            )
        )
    end
end

function assertions.fails(callback: function(), pattern: string, description: string)
    local ok, error_message: boolean, any = pcall(callback)
    if ok then
        raise(description, "expected an error, none was raised")
    end
    if pattern and not tostring(error_message):find(pattern) then
        raise(
            description,
            ("expected error matching %s, got %s"):format(
                pattern, describe_value(error_message)
            )
        )
    end
end

function assertions.succeeds(callback: function(), description: string)
    local ok, error_message: boolean, any = pcall(callback)
    if not ok then
        raise(description, ("unexpected error: %s"):format(tostring(error_message)))
    end
end

return assertions
