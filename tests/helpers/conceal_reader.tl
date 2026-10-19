local extmark_reader = require("helpers.extmark_reader")

local HIDDEN_CONCEAL <const> = ""

local record conceal_reader
end

function conceal_reader.visible_text(buf: integer, row: integer): string
    local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
    local hidden_columns: {integer: boolean} = {}
    for _, entry in ipairs(extmark_reader.on_row(buf, row)) do
        if entry.details.conceal == HIDDEN_CONCEAL then
            for column = entry.col + 1, entry.details.end_col do
                hidden_columns[column] = true
            end
        end
    end
    local visible: {string} = {}
    for column = 1, #line do
        if not hidden_columns[column] then
            visible[#visible + 1] = line:sub(column, column)
        end
    end
    return table.concat(visible)
end

function conceal_reader.concealed_texts(buf: integer, row: integer): {string}
    local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
    local texts: {string} = {}
    for _, entry in ipairs(extmark_reader.on_row(buf, row)) do
        if entry.details.conceal == HIDDEN_CONCEAL then
            texts[#texts + 1] = line:sub(entry.col + 1, entry.details.end_col)
        end
    end
    table.sort(texts)
    return texts
end

function conceal_reader.highlighted_text(
    buf: integer, row: integer, highlight_group: string
): string
    local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
    for _, entry in ipairs(extmark_reader.on_row(buf, row)) do
        if entry.details.hl_group == highlight_group then
            return line:sub(entry.col + 1, entry.details.end_col)
        end
    end
    return nil
end

return conceal_reader
