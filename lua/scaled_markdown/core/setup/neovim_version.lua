local MINIMUM_NEOVIM_FEATURE = 'nvim-0.12'

---@class neovim_version
local neovim_version = {}

neovim_version.MINIMUM_VERSION_TEXT = '0.12'

---@return boolean
function neovim_version.is_supported()
  return vim.fn.has(MINIMUM_NEOVIM_FEATURE) == 1
end

return neovim_version
