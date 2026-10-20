local DEFAULT_LATEX_CONFIG = require 'scaled_markdown.mods.latex.default_config'
local expect = require 'harness.assertions'
local latex_converter = require 'scaled_markdown.mods.latex.latex_converter'
local spec = require 'harness.spec'

---@param source string
---@return string
local function convert(source)
  return latex_converter.convert(source, DEFAULT_LATEX_CONFIG.command_symbols)
end

---@param cases [string, string][]
local function expect_conversions(cases)
  for _, case in ipairs(cases) do
    expect.equal(convert(case[1]), case[2], case[1])
  end
end

spec.describe('latex_converter', function()
  spec.it(
    'replaces symbol commands with unicode',
    function()
      expect_conversions {
        { [[\alpha + \beta]], 'α + β' },
        { [[a \leq b \neq c]], 'a ≤ b ≠ c' },
        { [[x \to \infty]], 'x → ∞' },
        { [[\sin x]], 'sin x' },
        { [[\alpha2]], 'α2' },
      }
    end
  )

  spec.it(
    'maps scripts when every character has a unicode form',
    function()
      expect_conversions {
        { [[x^2 + y_i]], 'x² + yᵢ' },
        { [[e^{-x}]], 'e⁻ˣ' },
        { [[\sum_{i=1}^{n}]], '∑ᵢ₌₁ⁿ' },
        { [[x^{2}_{3}]], 'x²₃' },
      }
    end
  )

  spec.it(
    'falls back to caret notation for unmapped scripts',
    function()
      expect_conversions {
        { [[x^q]], 'x^q' },
        { [[x^{qb}]], 'x^(qb)' },
        { [[a_b]], 'a_b' },
      }
    end
  )

  spec.it(
    'renders fractions, roots and binomials on one line',
    function()
      expect_conversions {
        { [[\frac{1}{2}]], '¹⁄₂' },
        { [[\frac{a}{b}]], 'a/b' },
        { [[\frac{a+b}{c}]], '(a+b)/c' },
        { [[\sqrt{x}]], '√x\u{0305}' },
        { [[\sqrt{x+1}]], '√x\u{0305}+\u{0305}1\u{0305}' },
        { [[\sqrt[3]{x}]], '∛x\u{0305}' },
        { [[\sqrt[n]{x}]], 'ⁿ√x\u{0305}' },
        { [[\binom{n}{k}]], 'C(n, k)' },
      }
    end
  )

  spec.it(
    'applies font alphabets and accents',
    function()
      expect_conversions {
        { [[\mathbb{R}]], 'ℝ' },
        { [[\mathbb{A}]], '𝔸' },
        { [[\mathcal{L}]], 'ℒ' },
        { [[\mathbf{v1}]], '𝐯𝟏' },
        { [[\hat{x}]], 'x\u{0302}' },
        { [[\vec{v}]], 'v\u{20D7}' },
      }
    end
  )

  spec.it(
    'keeps text arguments verbatim',
    function()
      expect_conversions {
        { [[\text{a {b} c}]], 'a {b} c' },
        { [[\operatorname{rank}]], 'rank' },
      }
    end
  )

  spec.it(
    'drops layout commands',
    function()
      expect_conversions {
        { [[\left( x \right)]], '( x )' },
        { [[\left. x \right|]], 'x |' },
        { [[\begin{aligned} a &= b \\ c &= d \end{aligned}]], 'a = b   c = d' },
        { [[a\,b\!c]], 'a bc' },
      }
    end
  )

  spec.it(
    'keeps unknown commands as source',
    function()
      expect_conversions {
        { [[\unknown]], [[\unknown]] },
      }
    end
  )

  spec.it(
    'degrades malformed input without raising',
    function()
      expect_conversions {
        { '{', '' },
        { '}', '}' },
        { 'x^', 'x^' },
        { 'x_', 'x_' },
        { [[\]], [[\]] },
        { [[\frac{}{}]], '/' },
        { [[\frac{a]], [[\fraca]] },
        { [[\sqrt]], '√' },
        { [[\sqrt[3]], '∛' },
        { [[\hat]], [[\hat]] },
        { [[\mathbb]], [[\mathbb]] },
        { '', '' },
      }
    end
  )

  spec.it(
    'uses the given command symbols',
    function()
      expect.equal(
        latex_converter.convert([[\star \alpha]], { star = '★' }),
        [[★ \alpha]],
        'custom symbols'
      )
    end
  )
end)
