local type ExtmarkEntryProps = require("helpers.types.extmark_entry_props")
local type ExtmarkPredicateProps = require("helpers.types.extmark_predicate_props")
local render_pipeline = require("scaled_markdown.core.render.render_pipeline")

local record extmark_reader
end

local function to_entry(extmark: vim.ExtmarkProps): ExtmarkEntryProps
    return {row = extmark[2], col = extmark[3], details = extmark[4]}
end

local function join_chunks(chunks: {vim.VirtualChunkProps}): string
    local parts: {string} = {}
    for _, chunk in ipairs(chunks or {}) do
        parts[#parts + 1] = chunk[1]
    end
    return table.concat(parts)
end

function extmark_reader.list(buf: integer): {ExtmarkEntryProps}
    local entries: {ExtmarkEntryProps} = {}
    for _, extmark in ipairs(
        vim.api.nvim_buf_get_extmarks(
            buf, render_pipeline.namespace_id(), 0, -1, {details = true}
        )
    ) do
        entries[#entries + 1] = to_entry(extmark)
    end
    return entries
end

function extmark_reader.on_row(buf: integer, row: integer): {ExtmarkEntryProps}
    return vim.tbl_filter(
        function(entry: ExtmarkEntryProps): boolean return entry.row == row end,
        extmark_reader.list(buf)
    )
end

function extmark_reader.find_all(
    buf: integer, predicate: ExtmarkPredicateProps
): {ExtmarkEntryProps}
    return vim.tbl_filter(
        function(entry: ExtmarkEntryProps): boolean
            return predicate(entry.details, entry)
        end,
        extmark_reader.list(buf)
    )
end

function extmark_reader.find(
    buf: integer, predicate: ExtmarkPredicateProps
): ExtmarkEntryProps
    return extmark_reader.find_all(buf, predicate)[1]
end

function extmark_reader.virt_text_string(details: vim.ExtmarkOptionsProps): string
    return join_chunks(details.virt_text)
end

function extmark_reader.virt_line_string(virt_line: {vim.VirtualChunkProps}): string
    return join_chunks(virt_line)
end

return extmark_reader
