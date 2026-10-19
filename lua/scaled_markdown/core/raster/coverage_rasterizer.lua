local STRIDE_PADDING = 2
local FULL_COVERAGE = 1

---@class coverage_rasterizer
local coverage_rasterizer = {}

---@param canvas RasterCanvasProps
---@param x number
---@return number
local function clamp_x(canvas, x) return math.max(0, math.min(canvas.width, x)) end

---@param width integer
---@param height integer
---@return RasterCanvasProps
function coverage_rasterizer.create_canvas(width, height)
  local stride = width + STRIDE_PADDING
  ---@type number[]
  local accumulation = {}
  for index = 1, stride * height do
    accumulation[index] = 0
  end
  return {
    width = width,
    height = height,
    stride = stride,
    accumulation = accumulation,
  }
end

---@param accumulation number[]
---@param index integer
---@param amount number
local function add_coverage(accumulation, index, amount)
  accumulation[index] = accumulation[index] + amount
end

---@param accumulation number[]
---@param row_base integer
---@param start_x number
---@param end_x number
---@param signed_height number
local function accumulate_row(
  accumulation,
  row_base,
  start_x,
  end_x,
  signed_height
)
  local left_x, right_x = start_x, end_x
  if left_x > right_x then
    left_x, right_x = right_x, left_x
  end
  local left_column = math.floor(left_x)
  local right_column = math.ceil(right_x)
  if right_column <= left_column + 1 then
    local middle_fraction = 0.5 * (start_x + end_x) - left_column
    add_coverage(
      accumulation,
      row_base + left_column,
      signed_height * (1 - middle_fraction)
    )
    add_coverage(
      accumulation,
      row_base + left_column + 1,
      signed_height * middle_fraction
    )
    return
  end
  local inverse_width = 1 / (right_x - left_x)
  local left_fraction = left_x - left_column
  local first_area = 0.5 * inverse_width * (1 - left_fraction) ^ 2
  local right_fraction = right_x - right_column + 1
  local last_area = 0.5 * inverse_width * right_fraction ^ 2
  add_coverage(accumulation, row_base + left_column, signed_height * first_area)
  if right_column == left_column + 2 then
    add_coverage(
      accumulation,
      row_base + left_column + 1,
      signed_height * (1 - first_area - last_area)
    )
  else
    local second_area = inverse_width * (1.5 - left_fraction)
    add_coverage(
      accumulation,
      row_base + left_column + 1,
      signed_height * (second_area - first_area)
    )
    for column = left_column + 2, right_column - 2 do
      add_coverage(
        accumulation,
        row_base + column,
        signed_height * inverse_width
      )
    end
    local before_last_area = second_area
      + (right_column - left_column - 3) * inverse_width
    add_coverage(
      accumulation,
      row_base + right_column - 1,
      signed_height * (1 - before_last_area - last_area)
    )
  end
  add_coverage(accumulation, row_base + right_column, signed_height * last_area)
end

---@param canvas RasterCanvasProps
---@param start_x number
---@param start_y number
---@param end_x number
---@param end_y number
function coverage_rasterizer.draw_line(canvas, start_x, start_y, end_x, end_y)
  if start_y == end_y then return end
  local direction = 1
  if start_y > end_y then
    start_x, end_x = end_x, start_x
    start_y, end_y = end_y, start_y
    direction = -1
  end
  start_x = clamp_x(canvas, start_x)
  end_x = clamp_x(canvas, end_x)
  local slope = (end_x - start_x) / (end_y - start_y)
  local x = start_x
  local first_row = math.floor(start_y)
  if start_y < 0 then
    x = start_x - start_y * slope
    first_row = 0
  end
  local last_row = math.min(canvas.height, math.ceil(end_y)) - 1
  for row = first_row, last_row do
    local row_height = math.min(row + 1, end_y) - math.max(row, start_y)
    local next_x = x + slope * row_height
    accumulate_row(
      canvas.accumulation,
      row * canvas.stride + 1,
      x,
      next_x,
      row_height * direction
    )
    x = next_x
  end
end

---@param canvas RasterCanvasProps
---@return CoverageBitmapProps
function coverage_rasterizer.to_bitmap(canvas)
  ---@type number[]
  local values = {}
  local accumulation = canvas.accumulation
  for row = 0, canvas.height - 1 do
    local running_sum = 0.0
    local row_base = row * canvas.stride
    local output_base = row * canvas.width
    for column = 1, canvas.width do
      running_sum = running_sum + accumulation[row_base + column]
      values[output_base + column] =
        math.min(FULL_COVERAGE, math.abs(running_sum))
    end
  end
  return { width = canvas.width, height = canvas.height, values = values }
end

return coverage_rasterizer
