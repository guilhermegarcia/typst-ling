local config = require("typst-ling.config")

local M = {}

local function define_commands()
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

function M.setup(opts)
  config.setup(opts)
end

function M.pick_functions()
  require("typst-ling.picker").open()
end

function M.tree_indent()
  require("typst-ling.tree").reindent_current()
end

define_commands()

return M
