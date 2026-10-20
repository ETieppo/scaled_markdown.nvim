local DEFAULT_LATEX_CONFIG = require 'scaled_markdown.mods.latex.default_config'
local expect = require 'harness.assertions'
local latex_converter = require 'scaled_markdown.mods.latex.latex_converter'
local spec = require 'harness.spec'

local TRAILING_WHITESPACE_PATTERN = '%s+$'

---@type string[]
local MALFORMED_SOURCES = {
  '',
  '{',
  '}',
  'x^',
  '^2',
  [[\]],
  [[\frac{a]],
  [[\frac{}{}]],
  [[\sqrt]],
  [[\sqrt[3]],
  [[\left( x]],
  [[x \right)]],
  [[\begin{pmatrix} a &]],
  [[\end{cases}]],
  'a & b \\\\',
}

---@param source string
---@return string[]
local function layout_lines(source)
  local box =
    latex_converter.layout(source, DEFAULT_LATEX_CONFIG.command_symbols)
  ---@type string[]
  local lines = {}
  for line_index, line in ipairs(box.lines) do
    lines[line_index] = line:gsub(TRAILING_WHITESPACE_PATTERN, '')
  end
  return lines
end

spec.describe('latex_box_renderer', function()
  spec.it(
    'stacks limits and grows delimiters around fractions',
    function()
      expect.deep_equal(
        layout_lines [[\lim_{n \to \infty} \left(1+\frac{1}{n}\right)^n]],
        {
          '      ⎛     1 ⎞ⁿ',
          ' lim  ⎜1 + ───⎟',
          'n → ∞ ⎝     n ⎠',
        },
        'limit'
      )
    end
  )

  spec.it(
    'draws a bar over short roots and spaces operators',
    function()
      expect.deep_equal(
        layout_lines [[\sqrt{3x-1}+(1+x)^2]],
        { ' ______', '√3x − 1 + (1 + x)²' },
        'root'
      )
    end
  )

  spec.it(
    'keeps unary signs tight',
    function()
      expect.deep_equal(
        layout_lines [[x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}]],
        {
          '           ________',
          '     −b ± √b² − 4ac',
          'x = ────────────────',
          '           2a',
        },
        'quadratic formula'
      )
    end
  )

  spec.it(
    'draws tall roots with a stem and index',
    function()
      expect.deep_equal(
        layout_lines [[\sqrt[3]{\frac{a}{b}}]],
        { '  ┌───', '  │ a', '  │───', '³╲│ b' },
        'cube root'
      )
    end
  )

  spec.it(
    'aligns matrix cells inside growing delimiters',
    function()
      expect.deep_equal(
        layout_lines [[\begin{pmatrix} a & b \\ c & d \end{pmatrix}]],
        { '⎛a  b⎞', '⎝c  d⎠' },
        'matrix'
      )
    end
  )

  spec.it(
    'aligns equations at the ampersand',
    function()
      expect.deep_equal(
        layout_lines [[a &= b + c \\ &= d]],
        { 'a = b + c', '  = d' },
        'aligned'
      )
    end
  )

  spec.it('raises scripts without a unicode form', function()
    expect.deep_equal(layout_lines 'x^q', { ' q', 'x' }, 'raised')
    expect.deep_equal(layout_lines 'x_i^2', { 'xᵢ²' }, 'inline scripts')
    expect.deep_equal(layout_lines 'e^{-x^2}', { 'e⁻ˣ²' }, 'nested script')
  end)

  spec.it('lays out malformed input without raising', function()
    for _, source in ipairs(MALFORMED_SOURCES) do
      local ok, box = pcall(
        latex_converter.layout,
        source,
        DEFAULT_LATEX_CONFIG.command_symbols
      )
      expect.truthy(ok, 'layout of ' .. source)
      expect.at_least(#box.lines, 1, 'lines of ' .. source)
      expect.truthy(
        pcall(
          latex_converter.convert,
          source,
          DEFAULT_LATEX_CONFIG.command_symbols
        ),
        'convert of ' .. source
      )
    end
  end)
end)
