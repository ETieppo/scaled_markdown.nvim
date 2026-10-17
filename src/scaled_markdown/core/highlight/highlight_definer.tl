local type HighlightDefinitionsProps =
  require 'scaled_markdown.core.types.highlight_definitions_props'

local record highlight_definer
end

function highlight_definer.define_all(
  highlight_props_by_group: HighlightDefinitionsProps
)
  for group_name, highlight_props in pairs(highlight_props_by_group) do
    vim.api.nvim_set_hl(
      0,
      group_name,
      vim.tbl_extend(
        'force',
        { default = true } as vim.HighlightProps,
        highlight_props
      )
    )
  end
end

return highlight_definer
