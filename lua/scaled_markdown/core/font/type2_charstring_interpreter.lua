local PATH_COMMAND_KIND_ENUM =
  require 'scaled_markdown.core.enums.path_command_kind_enum'
local compact_font_structure_reader =
  require 'scaled_markdown.core.font.compact_font_structure_reader'
local font_binary_reader =
  require 'scaled_markdown.core.font.font_binary_reader'

local MAX_SUBROUTINE_DEPTH = 10
local SMALL_SUBROUTINE_COUNT = 1240
local MEDIUM_SUBROUTINE_COUNT = 33900
local SMALL_SUBROUTINE_BIAS = 107
local MEDIUM_SUBROUTINE_BIAS = 1131
local LARGE_SUBROUTINE_BIAS = 32768
local SHORT_INTEGER_PREFIX = 28
local FIXED_NUMBER_PREFIX = 255
local SMALL_INTEGER_FIRST = 32
local SMALL_INTEGER_LAST = 246
local SMALL_INTEGER_BIAS = 139
local POSITIVE_INTEGER_LAST = 250
local POSITIVE_INTEGER_FIRST = 247
local NEGATIVE_INTEGER_FIRST = 251
local TWO_BYTE_INTEGER_BIAS = 108
local BYTE_RANGE = 256
local FIXED_DIVISOR = 65536
local MASK_BITS_PER_BYTE = 8

local OPERATOR_HORIZONTAL_STEM = 1
local OPERATOR_VERTICAL_STEM = 3
local OPERATOR_VERTICAL_MOVE = 4
local OPERATOR_RELATIVE_LINE = 5
local OPERATOR_HORIZONTAL_LINE = 6
local OPERATOR_VERTICAL_LINE = 7
local OPERATOR_RELATIVE_CURVE = 8
local OPERATOR_CALL_LOCAL_SUBROUTINE = 10
local OPERATOR_RETURN = 11
local OPERATOR_ESCAPE = 12
local OPERATOR_END_CHARACTER = 14
local OPERATOR_HORIZONTAL_STEM_HINT_MASK = 18
local OPERATOR_HINT_MASK = 19
local OPERATOR_COUNTER_MASK = 20
local OPERATOR_RELATIVE_MOVE = 21
local OPERATOR_HORIZONTAL_MOVE = 22
local OPERATOR_VERTICAL_STEM_HINT_MASK = 23
local OPERATOR_CURVE_LINE = 24
local OPERATOR_LINE_CURVE = 25
local OPERATOR_VERTICAL_VERTICAL_CURVE = 26
local OPERATOR_HORIZONTAL_HORIZONTAL_CURVE = 27
local OPERATOR_CALL_GLOBAL_SUBROUTINE = 29
local OPERATOR_VERTICAL_HORIZONTAL_CURVE = 30
local OPERATOR_HORIZONTAL_VERTICAL_CURVE = 31
local ESCAPED_HORIZONTAL_FLEX = 34
local ESCAPED_FLEX = 35
local ESCAPED_HORIZONTAL_FLEX_ONE = 36
local ESCAPED_FLEX_ONE = 37

---@class CharstringStateProps
---@field data string
---@field global_subroutines? CompactFontIndexProps
---@field local_subroutines? CompactFontIndexProps
---@field stack number[]
---@field commands PathCommandProps[]
---@field x number
---@field y number
---@field stem_count integer
---@field is_finished boolean

---@class type2_charstring_interpreter
local type2_charstring_interpreter = {}

---@param subroutines CompactFontIndexProps
---@return integer
local function compute_subroutine_bias(subroutines)
  if subroutines.count < SMALL_SUBROUTINE_COUNT then
    return SMALL_SUBROUTINE_BIAS
  end
  if subroutines.count < MEDIUM_SUBROUTINE_COUNT then
    return MEDIUM_SUBROUTINE_BIAS
  end
  return LARGE_SUBROUTINE_BIAS
end

---@param state CharstringStateProps
---@param dx number
---@param dy number
local function move_to(state, dx, dy)
  state.x = state.x + dx
  state.y = state.y + dy
  state.commands[#state.commands + 1] =
    { kind = PATH_COMMAND_KIND_ENUM.MOVE, x = state.x, y = state.y }
end

---@param state CharstringStateProps
---@param dx number
---@param dy number
local function line_to(state, dx, dy)
  state.x = state.x + dx
  state.y = state.y + dy
  state.commands[#state.commands + 1] =
    { kind = PATH_COMMAND_KIND_ENUM.LINE, x = state.x, y = state.y }
end

---@param state CharstringStateProps
---@param dx1 number
---@param dy1 number
---@param dx2 number
---@param dy2 number
---@param dx3 number
---@param dy3 number
local function curve_to(state, dx1, dy1, dx2, dy2, dx3, dy3)
  local control_x = state.x + dx1
  local control_y = state.y + dy1
  local second_control_x = control_x + dx2
  local second_control_y = control_y + dy2
  state.x = second_control_x + dx3
  state.y = second_control_y + dy3
  state.commands[#state.commands + 1] = {
    kind = PATH_COMMAND_KIND_ENUM.CUBIC,
    control_x = control_x,
    control_y = control_y,
    second_control_x = second_control_x,
    second_control_y = second_control_y,
    x = state.x,
    y = state.y,
  }
end

---@param state CharstringStateProps
local function count_stems(state)
  state.stem_count = state.stem_count + math.floor(#state.stack / 2)
end

---@param state CharstringStateProps
---@param starts_horizontal boolean
local function apply_alternating_lines(state, starts_horizontal)
  local is_horizontal = starts_horizontal
  for _, delta in ipairs(state.stack) do
    if is_horizontal then
      line_to(state, delta, 0)
    else
      line_to(state, 0, delta)
    end
    is_horizontal = not is_horizontal
  end
end

---@param state CharstringStateProps
---@param starts_horizontal boolean
local function apply_alternating_curves(state, starts_horizontal)
  local stack = state.stack
  local count = #stack
  local index = 1
  local is_horizontal = starts_horizontal
  while index + 3 <= count do
    local final_delta = count - index == 4 and stack[index + 4] or 0
    if is_horizontal then
      curve_to(
        state,
        stack[index],
        0,
        stack[index + 1],
        stack[index + 2],
        final_delta,
        stack[index + 3]
      )
    else
      curve_to(
        state,
        0,
        stack[index],
        stack[index + 1],
        stack[index + 2],
        stack[index + 3],
        final_delta
      )
    end
    index = index + 4
    is_horizontal = not is_horizontal
  end
end

---@param state CharstringStateProps
---@param is_horizontal boolean
local function apply_parallel_curves(state, is_horizontal)
  local stack = state.stack
  local count = #stack
  local index = 1
  local leading_delta = 0.0
  if count % 2 == 1 then
    leading_delta = stack[1]
    index = 2
  end
  while index + 3 <= count do
    if is_horizontal then
      curve_to(
        state,
        stack[index],
        leading_delta,
        stack[index + 1],
        stack[index + 2],
        stack[index + 3],
        0
      )
    else
      curve_to(
        state,
        leading_delta,
        stack[index],
        stack[index + 1],
        stack[index + 2],
        0,
        stack[index + 3]
      )
    end
    leading_delta = 0
    index = index + 4
  end
end

---@param state CharstringStateProps
---@param first_index integer
---@param last_index integer
---@return integer
local function apply_relative_curves(state, first_index, last_index)
  local stack = state.stack
  local index = first_index
  while index + 5 <= last_index do
    curve_to(
      state,
      stack[index],
      stack[index + 1],
      stack[index + 2],
      stack[index + 3],
      stack[index + 4],
      stack[index + 5]
    )
    index = index + 6
  end
  return index
end

---@param state CharstringStateProps
---@param first_index integer
---@param last_index integer
---@return integer
local function apply_relative_lines(state, first_index, last_index)
  local stack = state.stack
  local index = first_index
  while index + 1 <= last_index do
    line_to(state, stack[index], stack[index + 1])
    index = index + 2
  end
  return index
end

---@param state CharstringStateProps
local function apply_flex_one(state)
  local stack = state.stack
  local sum_x = stack[1] + stack[3] + stack[5] + stack[7] + stack[9]
  local sum_y = stack[2] + stack[4] + stack[6] + stack[8] + stack[10]
  curve_to(state, stack[1], stack[2], stack[3], stack[4], stack[5], stack[6])
  if math.abs(sum_x) > math.abs(sum_y) then
    curve_to(state, stack[7], stack[8], stack[9], stack[10], stack[11], -sum_y)
  else
    curve_to(state, stack[7], stack[8], stack[9], stack[10], -sum_x, stack[11])
  end
end

---@param state CharstringStateProps
---@param operator integer
local function apply_escaped_operator(state, operator)
  local stack = state.stack
  if operator == ESCAPED_HORIZONTAL_FLEX and #stack >= 7 then
    curve_to(state, stack[1], 0, stack[2], stack[3], stack[4], 0)
    curve_to(state, stack[5], 0, stack[6], -stack[3], stack[7], 0)
  elseif operator == ESCAPED_FLEX and #stack >= 12 then
    curve_to(state, stack[1], stack[2], stack[3], stack[4], stack[5], stack[6])
    curve_to(
      state,
      stack[7],
      stack[8],
      stack[9],
      stack[10],
      stack[11],
      stack[12]
    )
  elseif operator == ESCAPED_HORIZONTAL_FLEX_ONE and #stack >= 9 then
    curve_to(state, stack[1], stack[2], stack[3], stack[4], stack[5], 0)
    curve_to(
      state,
      stack[6],
      0,
      stack[7],
      stack[8],
      stack[9],
      -(stack[2] + stack[4] + stack[8])
    )
  elseif operator == ESCAPED_FLEX_ONE and #stack >= 11 then
    apply_flex_one(state)
  end
end

---@param state CharstringStateProps
---@param operator integer
local function apply_path_operator(state, operator)
  local stack = state.stack
  local count = #stack
  if operator == OPERATOR_RELATIVE_MOVE and count >= 2 then
    move_to(state, stack[count - 1], stack[count])
  elseif operator == OPERATOR_HORIZONTAL_MOVE and count >= 1 then
    move_to(state, stack[count], 0)
  elseif operator == OPERATOR_VERTICAL_MOVE and count >= 1 then
    move_to(state, 0, stack[count])
  elseif operator == OPERATOR_RELATIVE_LINE then
    apply_relative_lines(state, 1, count)
  elseif operator == OPERATOR_HORIZONTAL_LINE then
    apply_alternating_lines(state, true)
  elseif operator == OPERATOR_VERTICAL_LINE then
    apply_alternating_lines(state, false)
  elseif operator == OPERATOR_RELATIVE_CURVE then
    apply_relative_curves(state, 1, count)
  elseif operator == OPERATOR_CURVE_LINE then
    local index = apply_relative_curves(state, 1, count - 2)
    apply_relative_lines(state, index, count)
  elseif operator == OPERATOR_LINE_CURVE then
    local index = apply_relative_lines(state, 1, count - 6)
    apply_relative_curves(state, index, count)
  elseif operator == OPERATOR_VERTICAL_VERTICAL_CURVE then
    apply_parallel_curves(state, false)
  elseif operator == OPERATOR_HORIZONTAL_HORIZONTAL_CURVE then
    apply_parallel_curves(state, true)
  elseif operator == OPERATOR_VERTICAL_HORIZONTAL_CURVE then
    apply_alternating_curves(state, false)
  elseif operator == OPERATOR_HORIZONTAL_VERTICAL_CURVE then
    apply_alternating_curves(state, true)
  end
end

---@param data string
---@param offset integer
---@return number?
---@return integer
local function read_operand(data, offset)
  local first_byte = font_binary_reader.read_uint8(data, offset)
  if first_byte >= SMALL_INTEGER_FIRST and first_byte <= SMALL_INTEGER_LAST then
    return first_byte - SMALL_INTEGER_BIAS, offset + 1
  end
  if
    first_byte >= POSITIVE_INTEGER_FIRST
    and first_byte <= POSITIVE_INTEGER_LAST
  then
    return (first_byte - POSITIVE_INTEGER_FIRST) * BYTE_RANGE
      + font_binary_reader.read_uint8(data, offset + 1)
      + TWO_BYTE_INTEGER_BIAS,
      offset + 2
  end
  if first_byte == SHORT_INTEGER_PREFIX then
    return font_binary_reader.read_int16(data, offset + 1), offset + 3
  end
  if first_byte == FIXED_NUMBER_PREFIX then
    return font_binary_reader.read_int32(data, offset + 1) / FIXED_DIVISOR,
      offset + 5
  end
  if first_byte >= NEGATIVE_INTEGER_FIRST then
    return -(first_byte - NEGATIVE_INTEGER_FIRST) * BYTE_RANGE
      - font_binary_reader.read_uint8(data, offset + 1)
      - TWO_BYTE_INTEGER_BIAS,
      offset + 2
  end
  return nil, offset + 1
end

---@param first_byte integer
---@return boolean
local function is_operand_start(first_byte)
  return first_byte >= SMALL_INTEGER_FIRST or first_byte == SHORT_INTEGER_PREFIX
end

---@type fun(state: CharstringStateProps, start_offset: integer, end_offset: integer, depth: integer)
local execute

---@param state CharstringStateProps
---@param subroutines CompactFontIndexProps
---@param depth integer
local function call_subroutine(state, subroutines, depth)
  local subroutine_number = table.remove(state.stack)
  if
    not subroutine_number
    or not subroutines
    or depth >= MAX_SUBROUTINE_DEPTH
  then
    state.is_finished = true
    return
  end
  local start_offset, end_offset = compact_font_structure_reader.item_range(
    state.data,
    subroutines,
    math.floor(subroutine_number) + compute_subroutine_bias(subroutines)
  )
  if not start_offset or not end_offset then
    state.is_finished = true
    return
  end
  execute(state, start_offset, end_offset, depth + 1)
end

---@param state CharstringStateProps
---@param start_offset integer
---@param end_offset integer
---@param depth integer
execute = function(state, start_offset, end_offset, depth)
  local data = state.data
  local offset = start_offset
  while offset < end_offset and not state.is_finished do
    local first_byte = font_binary_reader.read_uint8(data, offset)
    if is_operand_start(first_byte) then
      ---@type number?
      local operand
      operand, offset = read_operand(data, offset)
      state.stack[#state.stack + 1] = operand
    else
      offset = offset + 1
      if first_byte == OPERATOR_RETURN then return end
      if first_byte == OPERATOR_CALL_LOCAL_SUBROUTINE then
        call_subroutine(state, state.local_subroutines, depth)
      elseif first_byte == OPERATOR_CALL_GLOBAL_SUBROUTINE then
        call_subroutine(state, state.global_subroutines, depth)
      else
        if
          first_byte == OPERATOR_HORIZONTAL_STEM
          or first_byte == OPERATOR_VERTICAL_STEM
          or first_byte == OPERATOR_HORIZONTAL_STEM_HINT_MASK
          or first_byte == OPERATOR_VERTICAL_STEM_HINT_MASK
        then
          count_stems(state)
        elseif
          first_byte == OPERATOR_HINT_MASK
          or first_byte == OPERATOR_COUNTER_MASK
        then
          count_stems(state)
          offset = offset
            + math.floor(
              (state.stem_count + MASK_BITS_PER_BYTE - 1) / MASK_BITS_PER_BYTE
            )
        elseif first_byte == OPERATOR_END_CHARACTER then
          state.is_finished = true
        elseif first_byte == OPERATOR_ESCAPE then
          apply_escaped_operator(
            state,
            font_binary_reader.read_uint8(data, offset)
          )
          offset = offset + 1
        else
          apply_path_operator(state, first_byte)
        end
        state.stack = {}
      end
    end
  end
end

---@param data string
---@param start_offset integer
---@param end_offset integer
---@param global_subroutines? CompactFontIndexProps
---@param local_subroutines? CompactFontIndexProps
---@return GlyphOutlineProps
function type2_charstring_interpreter.interpret(
  data,
  start_offset,
  end_offset,
  global_subroutines,
  local_subroutines
)
  ---@type CharstringStateProps
  local state = {
    data = data,
    global_subroutines = global_subroutines,
    local_subroutines = local_subroutines,
    stack = {},
    commands = {},
    x = 0,
    y = 0,
    stem_count = 0,
    is_finished = false,
  }
  execute(state, start_offset, end_offset, 0)
  return { commands = state.commands }
end

return type2_charstring_interpreter
