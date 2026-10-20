local LATEX_COLUMN_ALIGNMENT_ENUM =
  require 'scaled_markdown.mods.latex.latex_column_alignment_enum'

local MATRIX_COLUMN_GAP = 2
local ALIGNED_COLUMN_GAP = 1

---@type LatexColumnAlignmentEnum[]
local CENTERED_COLUMNS = { LATEX_COLUMN_ALIGNMENT_ENUM.CENTER }
---@type LatexColumnAlignmentEnum[]
local ALIGNED_COLUMNS =
  { LATEX_COLUMN_ALIGNMENT_ENUM.RIGHT, LATEX_COLUMN_ALIGNMENT_ENUM.LEFT }
---@type LatexColumnAlignmentEnum[]
local LEFT_COLUMNS = { LATEX_COLUMN_ALIGNMENT_ENUM.LEFT }

---@param left_delimiter string
---@param right_delimiter string
---@return LatexEnvironmentProps
local function matrix(left_delimiter, right_delimiter)
  return {
    left_delimiter = left_delimiter,
    right_delimiter = right_delimiter,
    column_alignments = CENTERED_COLUMNS,
    column_gap = MATRIX_COLUMN_GAP,
    has_column_spec = false,
  }
end

---@type LatexEnvironmentProps
local ALIGNED_ENVIRONMENT = {
  left_delimiter = '',
  right_delimiter = '',
  column_alignments = ALIGNED_COLUMNS,
  column_gap = ALIGNED_COLUMN_GAP,
  has_column_spec = false,
}

---@type LatexEnvironmentProps
local GATHERED_ENVIRONMENT = {
  left_delimiter = '',
  right_delimiter = '',
  column_alignments = CENTERED_COLUMNS,
  column_gap = MATRIX_COLUMN_GAP,
  has_column_spec = false,
}

---@class LatexEnvironmentsProps
---@field DEFAULT LatexEnvironmentProps
---@field BY_NAME table<string, LatexEnvironmentProps>

---@type LatexEnvironmentsProps
local LATEX_ENVIRONMENTS = {
  DEFAULT = ALIGNED_ENVIRONMENT,
  BY_NAME = {
    matrix = matrix('', ''),
    smallmatrix = matrix('', ''),
    pmatrix = matrix('(', ')'),
    bmatrix = matrix('[', ']'),
    Bmatrix = matrix('{', '}'),
    vmatrix = matrix('|', '|'),
    Vmatrix = matrix('‖', '‖'),
    cases = {
      left_delimiter = '{',
      right_delimiter = '',
      column_alignments = LEFT_COLUMNS,
      column_gap = MATRIX_COLUMN_GAP,
      has_column_spec = false,
    },
    array = {
      left_delimiter = '',
      right_delimiter = '',
      column_alignments = CENTERED_COLUMNS,
      column_gap = MATRIX_COLUMN_GAP,
      has_column_spec = true,
    },
    aligned = ALIGNED_ENVIRONMENT,
    align = ALIGNED_ENVIRONMENT,
    ['align*'] = ALIGNED_ENVIRONMENT,
    alignat = ALIGNED_ENVIRONMENT,
    split = ALIGNED_ENVIRONMENT,
    eqnarray = ALIGNED_ENVIRONMENT,
    gather = GATHERED_ENVIRONMENT,
    ['gather*'] = GATHERED_ENVIRONMENT,
    gathered = GATHERED_ENVIRONMENT,
  },
}

return LATEX_ENVIRONMENTS
