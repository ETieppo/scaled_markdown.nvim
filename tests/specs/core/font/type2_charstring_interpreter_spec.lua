local PATH_COMMAND_KIND_ENUM =
  require 'scaled_markdown.core.enums.path_command_kind_enum'
local compact_font_structure_reader =
  require 'scaled_markdown.core.font.compact_font_structure_reader'
local expect = require 'harness.assertions'
local spec = require 'harness.spec'
local type2_charstring_interpreter =
  require 'scaled_markdown.core.font.type2_charstring_interpreter'

local OPERAND_BIAS = 139
local RELATIVE_MOVE = 21
local RELATIVE_LINE = 5
local RELATIVE_CURVE = 8
local HORIZONTAL_STEM_HINT_MASK = 18
local HINT_MASK = 19
local CALL_GLOBAL_SUBROUTINE = 29
local RETURN = 11
local END_CHARACTER = 14
local SUBROUTINE_BIAS = 107

---@param value integer
---@return string
local function operand(value) return string.char(value + OPERAND_BIAS) end

---@param code integer
---@return string
local function operator(code) return string.char(code) end

---@param charstring string
---@param global_subroutines? CompactFontIndexProps
---@return PathCommandProps[]
local function interpret(charstring, global_subroutines)
  local empty_index = compact_font_structure_reader.read_index('\0\0', 0)
  return type2_charstring_interpreter.interpret(
    charstring,
    0,
    #charstring,
    global_subroutines or empty_index,
    empty_index
  ).commands
end

---@param commands PathCommandProps[]
---@return string[]
local function summarize(commands)
  return vim.tbl_map(
    ---@param command PathCommandProps
    ---@return string
    function(command)
      return ('%s %g %g'):format(command.kind, command.x, command.y)
    end,
    commands
  )
end

spec.describe('type2_charstring_interpreter', function()
  spec.it('draws relative moves and lines', function()
    local charstring = operand(10)
      .. operand(20)
      .. operator(RELATIVE_MOVE)
      .. operand(30)
      .. operand(0)
      .. operator(RELATIVE_LINE)
      .. operator(END_CHARACTER)
    expect.deep_equal(
      summarize(interpret(charstring, nil)),
      { 'move 10 20', 'line 40 20' },
      'path'
    )
  end)

  spec.it('ignores the leading advance width operand', function()
    local charstring = operand(50)
      .. operand(10)
      .. operand(20)
      .. operator(RELATIVE_MOVE)
      .. operator(END_CHARACTER)
    expect.deep_equal(
      summarize(interpret(charstring, nil)),
      { 'move 10 20' },
      'move'
    )
  end)

  spec.it('skips hint mask bytes for the declared stems', function()
    local charstring = operand(1)
      .. operand(2)
      .. operand(3)
      .. operand(4)
      .. operator(HORIZONTAL_STEM_HINT_MASK)
      .. operator(HINT_MASK)
      .. '\255'
      .. operand(10)
      .. operand(20)
      .. operator(RELATIVE_MOVE)
      .. operator(END_CHARACTER)
    expect.deep_equal(
      summarize(interpret(charstring, nil)),
      { 'move 10 20' },
      'move'
    )
  end)

  spec.it('accumulates cubic curve control points', function()
    local charstring = operand(0)
      .. operand(0)
      .. operator(RELATIVE_MOVE)
      .. operand(1)
      .. operand(2)
      .. operand(3)
      .. operand(4)
      .. operand(5)
      .. operand(6)
      .. operator(RELATIVE_CURVE)
      .. operator(END_CHARACTER)
    local curve = interpret(charstring, nil)[2]
    expect.equal(curve.kind, PATH_COMMAND_KIND_ENUM.CUBIC, 'kind')
    expect.deep_equal({
      curve.control_x,
      curve.control_y,
      curve.second_control_x,
      curve.second_control_y,
      curve.x,
      curve.y,
    }, { 1, 2, 4, 6, 9, 12 }, 'control points')
  end)

  spec.it('executes biased global subroutines', function()
    local subroutine = operand(5)
      .. operand(5)
      .. operator(RELATIVE_LINE)
      .. operator(RETURN)
    local subroutine_index = '\0\1\1\1'
      .. string.char(#subroutine + 1)
      .. subroutine
    local charstring = operand(0)
      .. operand(0)
      .. operator(RELATIVE_MOVE)
      .. operand(-SUBROUTINE_BIAS)
      .. operator(CALL_GLOBAL_SUBROUTINE)
      .. operator(END_CHARACTER)
    local data = subroutine_index .. charstring
    local global_subroutines = compact_font_structure_reader.read_index(data, 0)
    local empty_index = compact_font_structure_reader.read_index('\0\0', 0)
    local commands = type2_charstring_interpreter.interpret(
      data,
      #subroutine_index,
      #data,
      global_subroutines,
      empty_index
    ).commands
    expect.deep_equal(
      summarize(commands),
      { 'move 0 0', 'line 5 5' },
      'subroutine line'
    )
  end)
end)
