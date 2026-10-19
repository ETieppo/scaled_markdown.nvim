---@class symbol_cell_matcher
local symbol_cell_matcher = {}

---@param subcell_coverages number[]
---@param candidates SymbolCandidateProps[]
---@return string
function symbol_cell_matcher.match(subcell_coverages, candidates)
  local best_character = candidates[1].character
  local best_cost = math.huge
  for _, candidate in ipairs(candidates) do
    local filled_subcells = candidate.filled_subcells
    ---@type number
    local cost = #filled_subcells
    for _, subcell_index in ipairs(filled_subcells) do
      cost = cost - 2 * subcell_coverages[subcell_index]
    end
    if cost < best_cost then
      best_cost = cost
      best_character = candidate.character
    end
  end
  return best_character
end

return symbol_cell_matcher
