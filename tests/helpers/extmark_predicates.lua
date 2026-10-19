local OVERLAY_POSITION = 'overlay'
local INLINE_POSITION = 'inline'

---@class extmark_predicates
local extmark_predicates = {}

---@param row integer
---@return ExtmarkPredicateProps
function extmark_predicates.overlay_on_row(row)
  return function(details, entry)
    return entry.row == row and details.virt_text_pos == OVERLAY_POSITION
  end
end

---@param row integer
---@return ExtmarkPredicateProps
function extmark_predicates.inline_on_row(row)
  return function(details, entry)
    return entry.row == row and details.virt_text_pos == INLINE_POSITION
  end
end

---@param details vim.api.keyset.set_extmark
---@return boolean
function extmark_predicates.is_inline(details)
  return details.virt_text_pos == INLINE_POSITION
end

---@param highlight_group string
---@return ExtmarkPredicateProps
function extmark_predicates.with_highlight(highlight_group)
  return function(details) return details.hl_group == highlight_group end
end

---@param details vim.api.keyset.set_extmark
---@return boolean
function extmark_predicates.has_conceal(details) return details.conceal ~= nil end

---@param details vim.api.keyset.set_extmark
---@return boolean
function extmark_predicates.virt_lines_above(details)
  return details.virt_lines ~= nil and details.virt_lines_above == true
end

---@param details vim.api.keyset.set_extmark
---@return boolean
function extmark_predicates.virt_lines_below(details)
  return details.virt_lines ~= nil and details.virt_lines_above ~= true
end

return extmark_predicates
