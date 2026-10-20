local expect = require 'harness.assertions'
local latex_symbol_highlighter =
  require 'scaled_markdown.mods.latex.latex_symbol_highlighter'
local spec = require 'harness.spec'

local MATH_GROUP = 'ScaledMarkdownLatex'

spec.describe('latex_symbol_highlighter', function()
  spec.it(
    'splits text into chunks per symbol class',
    function()
      expect.deep_equal(
        latex_symbol_highlighter.to_chunks '∑ sin(2π) ≤ ∞',
        {
          { '∑', 'ScaledMarkdownLatexLargeOperator' },
          { ' ', MATH_GROUP },
          { 'sin', 'ScaledMarkdownLatexFunction' },
          { '(', 'ScaledMarkdownLatexDelimiter' },
          { '2', 'ScaledMarkdownLatexNumber' },
          { 'π', 'ScaledMarkdownLatexGreek' },
          { ')', 'ScaledMarkdownLatexDelimiter' },
          { ' ', MATH_GROUP },
          { '≤', 'ScaledMarkdownLatexRelation' },
          { ' ', MATH_GROUP },
          { '∞', 'ScaledMarkdownLatexSymbol' },
        },
        'chunks'
      )
    end
  )

  spec.it(
    'keeps variables that only contain function names as math',
    function()
      expect.deep_equal(
        latex_symbol_highlighter.to_chunks 'basin',
        { { 'basin', MATH_GROUP } },
        'word'
      )
    end
  )

  spec.it(
    'merges neighbors of the same class',
    function()
      expect.deep_equal(
        latex_symbol_highlighter.to_chunks '───⎟',
        { { '───⎟', 'ScaledMarkdownLatexDelimiter' } },
        'structure'
      )
    end
  )
end)
