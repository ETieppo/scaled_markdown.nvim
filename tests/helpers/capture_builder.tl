local type CaptureProps = require("scaled_markdown.core.types.capture_props")
local LANGUAGE_ENUM = require("scaled_markdown.core.enums.language_enum")
local buffer_factory = require("helpers.buffer_factory")

local record capture_builder
end

function capture_builder.from_lines(
    lines: {string}, query_text: string
): {CaptureProps}, integer
    local buf = buffer_factory.from_lines(lines)
    local root = vim.treesitter.get_parser(buf, LANGUAGE_ENUM.MARKDOWN):parse()[1]:root(
    )
    local query = vim.treesitter.query.parse(LANGUAGE_ENUM.MARKDOWN, query_text)
    local captures: {CaptureProps} = {}
    for capture_id, node in query:iter_captures(root, buf) do
        local start_row, start_col, end_row, end_col = node:range()
        captures[#captures + 1] = {
            name = query.captures[capture_id],
            node = node,
            start_row = start_row,
            start_col = start_col,
            end_row = end_row,
            end_col = end_col,
            text = vim.treesitter.get_node_text(node, buf),
        }
    end
    return captures, buf
end

return capture_builder
