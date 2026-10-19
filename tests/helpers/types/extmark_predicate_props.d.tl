local type ExtmarkEntryProps = require("helpers.types.extmark_entry_props")

local type ExtmarkPredicateProps = function(
    details: vim.ExtmarkOptionsProps, entry: ExtmarkEntryProps
): boolean

return ExtmarkPredicateProps
