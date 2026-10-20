local SYMBOL_CELL_GEOMETRY =
  require 'scaled_markdown.core.symbolize.symbol_cell_geometry'

---@class symbol_cell_matcher
local symbol_cell_matcher = {}

---@param subcell_coverages number[]
---@return boolean
local function is_empty(subcell_coverages)
  for subcell_index = 1, SYMBOL_CELL_GEOMETRY.SUBCELL_COUNT do
    if subcell_coverages[subcell_index] > 0 then return false end
  end
  return true
end

---@param subcell_coverages number[]
---@param candidates SymbolCandidateProps[]
---@return string
function symbol_cell_matcher.match(subcell_coverages, candidates)
  if is_empty(subcell_coverages) then return candidates[1].character end
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
