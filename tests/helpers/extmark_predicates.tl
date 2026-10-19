local type ExtmarkEntryProps = require("helpers.types.extmark_entry_props")
local type ExtmarkPredicateProps = require("helpers.types.extmark_predicate_props")

local OVERLAY_POSITION <const> = "overlay"
local INLINE_POSITION <const> = "inline"

local record extmark_predicates
end

function extmark_predicates.overlay_on_row(row: integer): ExtmarkPredicateProps
    return function(details: vim.ExtmarkOptionsProps, entry: ExtmarkEntryProps): boolean
        return entry.row == row and details.virt_text_pos == OVERLAY_POSITION
    end
end

function extmark_predicates.inline_on_row(row: integer): ExtmarkPredicateProps
    return function(details: vim.ExtmarkOptionsProps, entry: ExtmarkEntryProps): boolean
        return entry.row == row and details.virt_text_pos == INLINE_POSITION
    end
end

function extmark_predicates.is_inline(details: vim.ExtmarkOptionsProps): boolean
    return details.virt_text_pos == INLINE_POSITION
end

function extmark_predicates.with_highlight(
    highlight_group: string
): ExtmarkPredicateProps
    return function(details: vim.ExtmarkOptionsProps): boolean
        return details.hl_group == highlight_group
    end
end

function extmark_predicates.has_conceal(details: vim.ExtmarkOptionsProps): boolean
    return details.conceal ~= nil
end

function extmark_predicates.virt_lines_above(details: vim.ExtmarkOptionsProps): boolean
    return details.virt_lines ~= nil and details.virt_lines_above == true
end

function extmark_predicates.virt_lines_below(details: vim.ExtmarkOptionsProps): boolean
    return details.virt_lines ~= nil and details.virt_lines_above ~= true
end

return extmark_predicates
