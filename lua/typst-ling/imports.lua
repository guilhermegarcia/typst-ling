local config = require("typst-ling.config")

local M = {}

local packages = { "phonokit", "synkit" }

local function current_buf(bufnr)
  if bufnr == nil or bufnr == 0 then
    return vim.api.nvim_get_current_buf()
  end
  return bufnr
end

local function buf_dir(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return vim.loop.cwd()
  end
  return vim.fs.dirname(name)
end

local function normalize(path)
  if not path or path == "" then
    return nil
  end
  return vim.fs.normalize(path)
end

local function resolve_relative(base_dir, import_path)
  local candidate = normalize(vim.fs.joinpath(base_dir, import_path))
  if candidate and vim.fn.filereadable(candidate) == 1 then
    return candidate
  end
  return nil
end

local function resolve_with_root(package, import_path)
  local root = config.opts[package .. "_root"]
  if not root or root == "" then
    return nil
  end

  local root_norm = normalize(root)
  local trimmed = import_path
  if trimmed == (package .. "/lib.typ") then
    return normalize(vim.fs.joinpath(root_norm, "lib.typ"))
  end

  local prefix = package .. "/"
  if trimmed:sub(1, #prefix) == prefix then
    return normalize(vim.fs.joinpath(root_norm, trimmed:sub(#prefix + 1)))
  end

  if trimmed == "lib.typ" then
    return normalize(vim.fs.joinpath(root_norm, "lib.typ"))
  end

  return nil
end

local function resolve_import_path(bufnr, package, import_path)
  if import_path:match("^@preview/") then
    return nil
  end

  local from_root = resolve_with_root(package, import_path)
  if from_root and vim.fn.filereadable(from_root) == 1 then
    return from_root
  end

  return resolve_relative(buf_dir(bufnr), import_path)
end

function M.in_typst_buffer(bufnr)
  bufnr = current_buf(bufnr)
  return vim.bo[bufnr].filetype == "typst"
end

function M.describe(bufnr)
  bufnr = current_buf(bufnr)
  if not M.in_typst_buffer(bufnr) then
    return {}
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local found = {}
  for _, line in ipairs(lines) do
    if line:match("^%s*#import") then
      local import_path = line:match('^%s*#import%s+"([^"]+)"')
      for _, package in ipairs(packages) do
        if line:find(package, 1, true) then
          local item = found[package] or { package = package }
          item.import_path = item.import_path or import_path
          if import_path and not item.lib_path then
            local resolved = resolve_import_path(bufnr, package, import_path)
            if resolved and resolved:match("/lib%.typ$") then
              item.lib_path = resolved
            end
          end
          found[package] = item
        end
      end
    end
  end

  local active = {}
  for _, package in ipairs(packages) do
    if found[package] then
      active[#active + 1] = found[package]
    end
  end
  return active
end

function M.detect(bufnr)
  local described = M.describe(bufnr)
  local active = {}
  for _, item in ipairs(described) do
    active[#active + 1] = item.package
  end
  return active
end

function M.has(bufnr, package)
  return vim.tbl_contains(M.detect(bufnr), package)
end

return M
