local PATH_COMMAND_KIND_ENUM =
  require 'scaled_markdown.core.enums.path_command_kind_enum'

local FLATNESS_TOLERANCE = 0.05
local QUADRATIC_ERROR_FACTOR = 0.25
local CUBIC_ERROR_FACTOR = 0.75
local MAX_SEGMENTS = 64

---@alias LineEmitterProps fun(start_x: number, start_y: number, end_x: number, end_y: number)

---@class outline_flattener
local outline_flattener = {}

---@param deviation number
---@param error_factor number
---@return integer
local function count_segments(deviation, error_factor)
  local segment_count =
    math.ceil(math.sqrt(deviation * error_factor / FLATNESS_TOLERANCE))
  return math.max(1, math.min(MAX_SEGMENTS, segment_count))
end

---@param first_x number
---@param first_y number
---@param middle_x number
---@param middle_y number
---@param last_x number
---@param last_y number
---@return number
local function second_difference(
  first_x,
  first_y,
  middle_x,
  middle_y,
  last_x,
  last_y
)
  local delta_x = first_x - 2 * middle_x + last_x
  local delta_y = first_y - 2 * middle_y + last_y
  return math.sqrt(delta_x * delta_x + delta_y * delta_y)
end

---@param outline GlyphOutlineProps
---@param offset_x number
---@param transform RasterTransformProps
---@param emit_line LineEmitterProps
function outline_flattener.flatten(outline, offset_x, transform, emit_line)
  ---@param x number
  ---@return number
  local function to_pixel_x(x)
    return transform.origin_x + (offset_x + x) * transform.scale_x
  end
  ---@param y number
  ---@return number
  local function to_pixel_y(y) return transform.origin_y - y * transform.scale_y end

  local current_x, current_y = 0.0, 0.0
  local start_x, start_y = 0.0, 0.0
  local has_contour = false

  local function close_contour()
    if has_contour and (current_x ~= start_x or current_y ~= start_y) then
      emit_line(current_x, current_y, start_x, start_y)
    end
  end

  ---@param x number
  ---@param y number
  local function line_to(x, y)
    emit_line(current_x, current_y, x, y)
    current_x, current_y = x, y
  end

  ---@param command PathCommandProps
  local function quadratic_to(command)
    local control_x = to_pixel_x(command.control_x)
    local control_y = to_pixel_y(command.control_y)
    local end_x = to_pixel_x(command.x)
    local end_y = to_pixel_y(command.y)
    local first_x, first_y = current_x, current_y
    local segment_count = count_segments(
      second_difference(first_x, first_y, control_x, control_y, end_x, end_y),
      QUADRATIC_ERROR_FACTOR
    )
    for segment_index = 1, segment_count do
      local t = segment_index / segment_count
      local inverse_t = 1 - t
      line_to(
        inverse_t * inverse_t * first_x
          + 2 * inverse_t * t * control_x
          + t * t * end_x,
        inverse_t * inverse_t * first_y
          + 2 * inverse_t * t * control_y
          + t * t * end_y
      )
    end
  end

  ---@param command PathCommandProps
  local function cubic_to(command)
    local control_x = to_pixel_x(command.control_x)
    local control_y = to_pixel_y(command.control_y)
    local second_control_x = to_pixel_x(command.second_control_x)
    local second_control_y = to_pixel_y(command.second_control_y)
    local end_x = to_pixel_x(command.x)
    local end_y = to_pixel_y(command.y)
    local first_x, first_y = current_x, current_y
    local deviation = math.max(
      second_difference(
        first_x,
        first_y,
        control_x,
        control_y,
        second_control_x,
        second_control_y
      ),
      second_difference(
        control_x,
        control_y,
        second_control_x,
        second_control_y,
        end_x,
        end_y
      )
    )
    local segment_count = count_segments(deviation, CUBIC_ERROR_FACTOR)
    for segment_index = 1, segment_count do
      local t = segment_index / segment_count
      local inverse_t = 1 - t
      local first_weight = inverse_t * inverse_t * inverse_t
      local second_weight = 3 * inverse_t * inverse_t * t
      local third_weight = 3 * inverse_t * t * t
      local fourth_weight = t * t * t
      line_to(
        first_weight * first_x
          + second_weight * control_x
          + third_weight * second_control_x
          + fourth_weight * end_x,
        first_weight * first_y
          + second_weight * control_y
          + third_weight * second_control_y
          + fourth_weight * end_y
      )
    end
  end

  for _, command in ipairs(outline.commands) do
    if command.kind == PATH_COMMAND_KIND_ENUM.MOVE then
      close_contour()
      current_x, current_y = to_pixel_x(command.x), to_pixel_y(command.y)
      start_x, start_y = current_x, current_y
      has_contour = true
    elseif command.kind == PATH_COMMAND_KIND_ENUM.LINE then
      line_to(to_pixel_x(command.x), to_pixel_y(command.y))
    elseif command.kind == PATH_COMMAND_KIND_ENUM.QUADRATIC then
      quadratic_to(command)
    elseif command.kind == PATH_COMMAND_KIND_ENUM.CUBIC then
      cubic_to(command)
    end
  end
  close_contour()
end

return outline_flattener
