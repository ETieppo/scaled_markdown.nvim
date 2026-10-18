


local highlight_definer = {}


function highlight_definer.define_all(
   highlight_props_by_group)

   for group_name, highlight_props in pairs(highlight_props_by_group) do
      vim.api.nvim_set_hl(
      0,
      group_name,
      vim.tbl_extend(
      'force',
      { default = true },
      highlight_props))


   end
end

return highlight_definer
