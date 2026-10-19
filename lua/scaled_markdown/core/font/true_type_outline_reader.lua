local PATH_COMMAND_KIND_ENUM =
  require 'scaled_markdown.core.enums.path_command_kind_enum'
local font_binary_reader =
  require 'scaled_markdown.core.font.font_binary_reader'

local SHORT_LOCATION_FORMAT = 0
local SHORT_LOCATION_MULTIPLIER = 2
local GLYPH_HEADER_LENGTH = 10
local MAX_COMPONENT_DEPTH = 8
local ON_CURVE_FLAG = 1
local X_SHORT_FLAG = 2
local Y_SHORT_FLAG = 4
local REPEAT_FLAG = 8
local X_SAME_OR_POSITIVE_FLAG = 16
local Y_SAME_OR_POSITIVE_FLAG = 32
local ARGUMENTS_ARE_WORDS_FLAG = 1
local ARGUMENTS_ARE_OFFSETS_FLAG = 2
local UNIFORM_SCALE_FLAG = 8
local MORE_COMPONENTS_FLAG = 32
local AXIS_SCALE_FLAG = 64
local MATRIX_SCALE_FLAG = 128

---@class GlyphPointProps
---@field x number
---@field y number
---@field is_on_curve boolean

---@class ComponentTransformProps
---@field xx number
---@field yx number
---@field xy number
---@field yy number
---@field dx number
---@field dy number

---@class true_type_outline_reader
local true_type_outline_reader = {}

---@param first GlyphPointProps
---@param second GlyphPointProps
---@return GlyphPointProps
local function midpoint(first, second)
  return {
    x = (first.x + second.x) / 2,
    y = (first.y + second.y) / 2,
    is_on_curve = true,
  }
end

---@param commands PathCommandProps[]
---@param points GlyphPointProps[]
---@param first_index integer
---@param last_index integer
local function append_contour(commands, points, first_index, last_index)
  if last_index < first_index then return end
  local first_point = points[first_index]
  local last_point = points[last_index]
  ---@type GlyphPointProps
  local start_point
  ---@type GlyphPointProps[]
  local ordered_points = {}
  if first_point.is_on_curve then
    start_point = first_point
    ordered_points = vim.list_slice(points, first_index + 1, last_index)
  elseif last_point.is_on_curve then
    start_point = last_point
    ordered_points = vim.list_slice(points, first_index, last_index - 1)
  else
    start_point = midpoint(first_point, last_point)
    ordered_points = vim.list_slice(points, first_index, last_index)
  end
  ordered_points[#ordered_points + 1] = start_point
  commands[#commands + 1] = {
    kind = PATH_COMMAND_KIND_ENUM.MOVE,
    x = start_point.x,
    y = start_point.y,
  }
  ---@type GlyphPointProps?
  local pending_control = nil
  for _, point in ipairs(ordered_points) do
    if point.is_on_curve then
      if pending_control then
        commands[#commands + 1] = {
          kind = PATH_COMMAND_KIND_ENUM.QUADRATIC,
          control_x = pending_control.x,
          control_y = pending_control.y,
          x = point.x,
          y = point.y,
        }
      else
        commands[#commands + 1] = {
          kind = PATH_COMMAND_KIND_ENUM.LINE,
          x = point.x,
          y = point.y,
        }
      end
      pending_control = nil
    else
      if pending_control then
        local implied_point = midpoint(pending_control, point)
        commands[#commands + 1] = {
          kind = PATH_COMMAND_KIND_ENUM.QUADRATIC,
          control_x = pending_control.x,
          control_y = pending_control.y,
          x = implied_point.x,
          y = implied_point.y,
        }
      end
      pending_control = point
    end
  end
end

---@param data string
---@param offset integer
---@param point_count integer
---@return integer[]
---@return integer
local function read_flags(data, offset, point_count)
  ---@type integer[]
  local flags = {}
  while #flags < point_count do
    local flag = font_binary_reader.read_uint8(data, offset)
    offset = offset + 1
    flags[#flags + 1] = flag
    if font_binary_reader.has_flag(flag, REPEAT_FLAG) then
      local repeat_count = font_binary_reader.read_uint8(data, offset)
      offset = offset + 1
      for _ = 1, repeat_count do
        flags[#flags + 1] = flag
      end
    end
  end
  return flags, offset
end

---@param data string
---@param offset integer
---@param flags integer[]
---@param point_count integer
---@param short_flag integer
---@param same_or_positive_flag integer
---@return number[]
---@return integer
local function read_coordinates(
  data,
  offset,
  flags,
  point_count,
  short_flag,
  same_or_positive_flag
)
  ---@type number[]
  local coordinates = {}
  local value = 0
  for point_index = 1, point_count do
    local flag = flags[point_index]
    if font_binary_reader.has_flag(flag, short_flag) then
      local delta = font_binary_reader.read_uint8(data, offset)
      offset = offset + 1
      value = value
        + (
          font_binary_reader.has_flag(flag, same_or_positive_flag) and delta
          or -delta
        )
    elseif not font_binary_reader.has_flag(flag, same_or_positive_flag) then
      value = value + font_binary_reader.read_int16(data, offset)
      offset = offset + 2
    end
    coordinates[point_index] = value
  end
  return coordinates, offset
end

---@param data string
---@param offset integer
---@param contour_count integer
---@return GlyphOutlineProps
local function read_simple_glyph(data, offset, contour_count)
  ---@type integer[]
  local end_points = {}
  for contour_index = 1, contour_count do
    end_points[contour_index] = font_binary_reader.read_uint16(
      data,
      offset + GLYPH_HEADER_LENGTH + (contour_index - 1) * 2
    ) + 1
  end
  local point_count = end_points[contour_count]
  local instructions_offset = offset + GLYPH_HEADER_LENGTH + contour_count * 2
  local flags_offset = instructions_offset
    + 2
    + font_binary_reader.read_uint16(data, instructions_offset)
  local flags, x_offset = read_flags(data, flags_offset, point_count)
  local x_values, y_offset = read_coordinates(
    data,
    x_offset,
    flags,
    point_count,
    X_SHORT_FLAG,
    X_SAME_OR_POSITIVE_FLAG
  )
  local y_values = read_coordinates(
    data,
    y_offset,
    flags,
    point_count,
    Y_SHORT_FLAG,
    Y_SAME_OR_POSITIVE_FLAG
  )
  ---@type GlyphPointProps[]
  local points = {}
  for point_index = 1, point_count do
    points[point_index] = {
      x = x_values[point_index],
      y = y_values[point_index],
      is_on_curve = font_binary_reader.has_flag(
        flags[point_index],
        ON_CURVE_FLAG
      ),
    }
  end
  ---@type PathCommandProps[]
  local commands = {}
  local first_index = 1
  for _, end_point in ipairs(end_points) do
    append_contour(commands, points, first_index, end_point)
    first_index = end_point + 1
  end
  return { commands = commands }
end

---@param command PathCommandProps
---@param transform ComponentTransformProps
---@return PathCommandProps
local function transform_command(command, transform)
  ---@param x number
  ---@param y number
  ---@return number?
  local function transform_x(x, y)
    if not x then return nil end
    return transform.xx * x + transform.xy * y + transform.dx
  end
  ---@param x number
  ---@param y number
  ---@return number?
  local function transform_y(x, y)
    if not x then return nil end
    return transform.yx * x + transform.yy * y + transform.dy
  end
  return {
    kind = command.kind,
    x = transform_x(command.x, command.y),
    y = transform_y(command.x, command.y),
    control_x = transform_x(command.control_x, command.control_y),
    control_y = transform_y(command.control_x, command.control_y),
  }
end

---@param data string
---@param offset integer
---@param flags integer
---@return ComponentTransformProps
---@return integer
local function read_component_transform(data, offset, flags)
  ---@type ComponentTransformProps
  local transform = { xx = 1, yx = 0, xy = 0, yy = 1, dx = 0, dy = 0 }
  local is_offset =
    font_binary_reader.has_flag(flags, ARGUMENTS_ARE_OFFSETS_FLAG)
  if font_binary_reader.has_flag(flags, ARGUMENTS_ARE_WORDS_FLAG) then
    transform.dx = is_offset and font_binary_reader.read_int16(data, offset)
      or 0
    transform.dy = is_offset and font_binary_reader.read_int16(data, offset + 2)
      or 0
    offset = offset + 4
  else
    transform.dx = is_offset and font_binary_reader.read_int8(data, offset) or 0
    transform.dy = is_offset and font_binary_reader.read_int8(data, offset + 1)
      or 0
    offset = offset + 2
  end
  if font_binary_reader.has_flag(flags, UNIFORM_SCALE_FLAG) then
    transform.xx = font_binary_reader.read_f2dot14(data, offset)
    transform.yy = transform.xx
    offset = offset + 2
  elseif font_binary_reader.has_flag(flags, AXIS_SCALE_FLAG) then
    transform.xx = font_binary_reader.read_f2dot14(data, offset)
    transform.yy = font_binary_reader.read_f2dot14(data, offset + 2)
    offset = offset + 4
  elseif font_binary_reader.has_flag(flags, MATRIX_SCALE_FLAG) then
    transform.xx = font_binary_reader.read_f2dot14(data, offset)
    transform.yx = font_binary_reader.read_f2dot14(data, offset + 2)
    transform.xy = font_binary_reader.read_f2dot14(data, offset + 4)
    transform.yy = font_binary_reader.read_f2dot14(data, offset + 6)
    offset = offset + 8
  end
  return transform, offset
end

---@param data string
---@param offset integer
---@param load_component fun(glyph_index: integer): GlyphOutlineProps?
---@return GlyphOutlineProps
local function read_composite_glyph(data, offset, load_component)
  ---@type PathCommandProps[]
  local commands = {}
  local component_offset = offset + GLYPH_HEADER_LENGTH
  local has_more_components = true
  while has_more_components do
    local flags = font_binary_reader.read_uint16(data, component_offset)
    local component_glyph_index =
      font_binary_reader.read_uint16(data, component_offset + 2)
    local transform, next_offset =
      read_component_transform(data, component_offset + 4, flags)
    local component_outline = load_component(component_glyph_index)
    for _, command in
      ipairs(component_outline and component_outline.commands or {})
    do
      commands[#commands + 1] = transform_command(command, transform)
    end
    component_offset = next_offset
    has_more_components =
      font_binary_reader.has_flag(flags, MORE_COMPONENTS_FLAG)
  end
  return { commands = commands }
end

---@param data string
---@param tables table<string, FontTableProps>
---@param glyph_count integer
---@param location_format integer
---@return GlyphOutlineLoaderProps?
function true_type_outline_reader.create_loader(
  data,
  tables,
  glyph_count,
  location_format
)
  local location_offset = tables.loca.offset
  local glyphs_offset = tables.glyf.offset

  ---@param glyph_index integer
  ---@return integer
  local function read_location(glyph_index)
    if location_format == SHORT_LOCATION_FORMAT then
      return font_binary_reader.read_uint16(
        data,
        location_offset + glyph_index * 2
      ) * SHORT_LOCATION_MULTIPLIER
    end
    return font_binary_reader.read_uint32(
      data,
      location_offset + glyph_index * 4
    )
  end

  ---@param glyph_index integer
  ---@param depth integer
  ---@return GlyphOutlineProps?
  local function load_glyph(glyph_index, depth)
    if glyph_index >= glyph_count or depth > MAX_COMPONENT_DEPTH then
      return nil
    end
    local glyph_start = read_location(glyph_index)
    if read_location(glyph_index + 1) <= glyph_start then
      return { commands = {} }
    end
    local glyph_offset = glyphs_offset + glyph_start
    local contour_count = font_binary_reader.read_int16(data, glyph_offset)
    if contour_count > 0 then
      return read_simple_glyph(data, glyph_offset, contour_count)
    end
    if contour_count < 0 then
      return read_composite_glyph(
        data,
        glyph_offset,
        ---@param component_glyph_index integer
        ---@return GlyphOutlineProps?
        function(component_glyph_index)
          return load_glyph(component_glyph_index, depth + 1)
        end
      )
    end
    return { commands = {} }
  end

  return function(glyph_index) return load_glyph(glyph_index, 0) end
end

return true_type_outline_reader
