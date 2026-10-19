local font_catalog = require 'scaled_markdown.core.font.font_catalog'
local font_query_parser = require 'scaled_markdown.core.font.font_query_parser'

local FALLBACK_GENERIC_FAMILY = 'sans'
local ITALIC_MISMATCH_PENALTY = 10000
local WIDTH_VARIANT_PENALTY = 5000
---@type string[]
local WIDTH_VARIANT_PATTERNS = {
  'condensed',
  'narrow',
  'compressed',
  'expanded',
  'extended',
  'wide',
}
---@type table<string, string[]>
local GENERIC_FAMILIES = {
  sans = {
    'DejaVu Sans',
    'Liberation Sans',
    'Noto Sans',
    'FreeSans',
    'Adwaita Sans',
    'Arial',
    'Helvetica',
    'Segoe UI',
  },
  sansserif = {
    'DejaVu Sans',
    'Liberation Sans',
    'Noto Sans',
    'FreeSans',
    'Adwaita Sans',
    'Arial',
    'Helvetica',
    'Segoe UI',
  },
  serif = {
    'DejaVu Serif',
    'Liberation Serif',
    'Noto Serif',
    'FreeSerif',
    'Times New Roman',
    'Times',
  },
  monospace = {
    'DejaVu Sans Mono',
    'Liberation Mono',
    'Noto Sans Mono',
    'FreeMono',
    'Adwaita Mono',
    'Menlo',
    'Consolas',
    'Courier New',
  },
  mono = {
    'DejaVu Sans Mono',
    'Liberation Mono',
    'Noto Sans Mono',
    'FreeMono',
    'Adwaita Mono',
    'Menlo',
    'Consolas',
    'Courier New',
  },
}

---@class font_matcher
local font_matcher = {}

---@param style_name string
---@return boolean
local function has_width_variant(style_name)
  local lower_style = style_name:lower()
  for _, pattern in ipairs(WIDTH_VARIANT_PATTERNS) do
    if lower_style:find(pattern, 1, true) then return true end
  end
  return false
end

---@param entry FontCatalogEntryProps
---@param query FontQueryProps
---@return number
local function score_entry(entry, query)
  local requested_style = (query.requested_style or ''):lower()
  local score = math.abs(entry.weight - query.weight)
  if entry.is_italic ~= query.is_italic then
    score = score + ITALIC_MISMATCH_PENALTY
  end
  if
    has_width_variant(entry.style_name)
    and not has_width_variant(requested_style)
  then
    score = score + WIDTH_VARIANT_PENALTY
  end
  return score + #entry.style_name / 100
end

---@param entry FontCatalogEntryProps
---@param normalized_family string
---@return boolean
local function matches_family(entry, normalized_family)
  for _, family_name in ipairs(entry.family_names) do
    if font_query_parser.normalize_family(family_name) == normalized_family then
      return true
    end
  end
  return false
end

---@param paths string[]
---@param normalized_family string
---@return FontCatalogEntryProps[]
local function collect_matches(paths, normalized_family)
  ---@type FontCatalogEntryProps[]
  local matches = {}
  for _, path in ipairs(paths) do
    for _, entry in ipairs(font_catalog.read_entries(path)) do
      if matches_family(entry, normalized_family) then
        matches[#matches + 1] = entry
      end
    end
  end
  return matches
end

---@param normalized_family string
---@return string[]
local function filter_likely_paths(normalized_family)
  return vim.tbl_filter(
    ---@param path string
    ---@return boolean
    function(path)
      local file_name = vim.fs.basename(path)
      return font_query_parser
        .normalize_family(file_name)
        :find(normalized_family, 1, true) ~= nil
    end,
    font_catalog.list_files()
  )
end

---@param family string
---@return FontCatalogEntryProps[]
local function find_family_entries(family)
  local normalized_family = font_query_parser.normalize_family(family)
  if normalized_family == '' then return {} end
  local matches =
    collect_matches(filter_likely_paths(normalized_family), normalized_family)
  if #matches > 0 then return matches end
  return collect_matches(font_catalog.list_files(), normalized_family)
end

---@param entries FontCatalogEntryProps[]
---@param query FontQueryProps
---@return FontCatalogEntryProps?
local function select_best(entries, query)
  ---@type FontCatalogEntryProps?
  local best_entry = nil
  local best_score = math.huge
  for _, entry in ipairs(entries) do
    local score = score_entry(entry, query)
    if score < best_score then
      best_score = score
      best_entry = entry
    end
  end
  return best_entry
end

---@param families string[]
---@param query FontQueryProps
---@return FontCatalogEntryProps?
local function match_families(families, query)
  for _, family in ipairs(families) do
    local entries = find_family_entries(family)
    if #entries > 0 then return select_best(entries, query) end
  end
  return nil
end

---@param query FontQueryProps
---@return FontCatalogEntryProps?
function font_matcher.match(query)
  local candidate_families = GENERIC_FAMILIES[font_query_parser.normalize_family(
    query.family
  )] or { query.family }
  return match_families(candidate_families, query)
    or match_families(GENERIC_FAMILIES[FALLBACK_GENERIC_FAMILY], query)
end

return font_matcher
