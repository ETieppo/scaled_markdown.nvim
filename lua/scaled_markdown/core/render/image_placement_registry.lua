---@class image_placement_registry
local image_placement_registry = {}

---@type table<integer, ImagePlacementProps[]>
local placements_by_buffer = {}

---@param buf integer
function image_placement_registry.clear(buf) placements_by_buffer[buf] = nil end

---@param buf integer
---@param placement ImagePlacementProps
function image_placement_registry.add(buf, placement)
  local placements = placements_by_buffer[buf] or {}
  placements[#placements + 1] = placement
  placements_by_buffer[buf] = placements
end

---@param buf integer
---@return ImagePlacementProps[]
function image_placement_registry.list(buf)
  return placements_by_buffer[buf] or {}
end

return image_placement_registry
