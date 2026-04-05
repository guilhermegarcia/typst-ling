local M = {}

local defaults = {
  phonokit_root = nil,
  synkit_root = nil,
}

M.opts = vim.deepcopy(defaults)

function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
end

return M

