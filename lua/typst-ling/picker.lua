local config = require("typst-ling.config")
local imports = require("typst-ling.imports")
local metadata = require("typst-ling.metadata")

local M = {}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "typst-ling" })
end

local function insert_template(template)
  local marker = "${cursor}"
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1

  local lines = vim.split(template, "\n", { plain = true })
  local target_row = row
  local target_col = col

  for idx, line in ipairs(lines) do
    local start_col = line:find(marker, 1, true)
    if start_col then
      lines[idx] = line:gsub(vim.pesc(marker), "", 1)
      target_row = row + idx - 1
      target_col = idx == 1 and (col + start_col - 1) or (start_col - 1)
      break
    end
  end

  vim.api.nvim_buf_set_text(0, row, col, row, col, lines)
  vim.api.nvim_win_set_cursor(0, { target_row + 1, target_col })
end

local function jump_to_item(item)
  local path = item.file
  if not path or path == "" then
    local root = config.opts[item.package .. "_root"]
    if not root or root == "" then
      notify(("No `%s` root configured for typst-ling."):format(item.package), vim.log.levels.WARN)
      return
    end
    path = vim.fs.joinpath(root, item.path)
  end

  if vim.fn.filereadable(path) == 0 then
    notify(("Source file not found: %s"):format(path), vim.log.levels.WARN)
    return
  end

  vim.cmd.edit(vim.fn.fnameescape(path))
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for idx, line in ipairs(lines) do
    if item.search and line:find(item.search, 1, true) then
      vim.api.nvim_win_set_cursor(0, { idx, 0 })
      vim.cmd("normal! zz")
      return
    end
  end
end

local function format_item(item)
  local ret = {}
  ret[#ret + 1] = { item.name, "Function" }
  ret[#ret + 1] = { "  " }
  ret[#ret + 1] = { item.package, "Identifier" }
  ret[#ret + 1] = { " • ", "Comment" }
  ret[#ret + 1] = { item.category, "Type" }
  ret[#ret + 1] = { "  " }
  ret[#ret + 1] = { item.description, "Comment" }
  return ret
end

function M.open()
  if not imports.in_typst_buffer(0) then
    notify("typst-ling only applies to Typst buffers.", vim.log.levels.WARN)
    return
  end

  local active = imports.describe(0)
  if #active == 0 then
    notify("No supported Typst package imported in this buffer.", vim.log.levels.INFO)
    return
  end

  local items = metadata.for_packages(active)
  if #items == 0 then
    notify("No typst-ling functions available for the active imports.", vim.log.levels.INFO)
    return
  end

  Snacks.picker.pick({
    source = "typst_ling",
    title = "Typst-Ling Functions",
    items = items,
    format = format_item,
    preview = "preview",
    layout = {
      preset = "vertical",
    },
    matcher = { sort_empty = true },
    confirm = function(picker, item)
      picker:close()
      if item then
        vim.schedule(function()
          insert_template(item.template)
        end)
      end
    end,
    actions = {
      jump_source = function(picker, item)
        picker:close()
        if item then
          vim.schedule(function()
            jump_to_item(item)
          end)
        end
      end,
    },
    win = {
      input = {
        keys = {
          ["<C-o>"] = { "jump_source", mode = { "n", "i" } },
        },
      },
      list = {
        keys = {
          ["<C-o>"] = { "jump_source", mode = { "n", "i" } },
        },
      },
    },
  })
end

return M
