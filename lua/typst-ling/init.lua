local config = require("typst-ling.config")

local M = {}

function M.setup(opts)
  config.setup(opts)

  if vim.fn.exists(":TypstLingFunctions") == 0 then
    vim.api.nvim_create_user_command("TypstLingFunctions", function()
      M.pick_functions()
    end, {
      desc = "Open the typst-ling function picker",
    })
  end

  if vim.fn.exists(":TypstLingTreeIndent") == 0 then
    vim.api.nvim_create_user_command("TypstLingTreeIndent", function()
      M.tree_indent()
    end, {
      desc = "Reindent the current synkit #tree() input",
    })
  end
end

function M.pick_functions()
  require("typst-ling.picker").open()
end

function M.tree_indent()
  require("typst-ling.tree").reindent_current()
end

return M
