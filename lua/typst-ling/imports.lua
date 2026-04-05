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

local function readable(path)
  return path and vim.fn.filereadable(path) == 1
end

local function resolve_relative(base_dir, import_path)
  local candidate = normalize(vim.fs.joinpath(base_dir, import_path))
  if readable(candidate) then
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

local function typst_package_roots()
  local roots = {}
  local home = vim.loop.os_homedir()
  local data_home = vim.env.XDG_DATA_HOME

  if data_home and data_home ~= "" then
    roots[#roots + 1] = vim.fs.joinpath(data_home, "typst", "packages")
  end

  roots[#roots + 1] = vim.fs.joinpath(home, ".local", "share", "typst", "packages")
  roots[#roots + 1] = vim.fs.joinpath(home, "Library", "Application Support", "typst", "packages")

  local unique = {}
  local ordered = {}
  for _, root in ipairs(roots) do
    local norm = normalize(root)
    if norm and not unique[norm] then
      unique[norm] = true
      ordered[#ordered + 1] = norm
    end
  end
  return ordered
end

local function resolve_typst_package(import_path)
  local namespace, name, version = import_path:match("^@([%w%-_]+)/([%w%-_]+):([%w%._%-]+)$")
  if not namespace or not name or not version then
    return nil
  end

  for _, root in ipairs(typst_package_roots()) do
    local candidate = normalize(vim.fs.joinpath(root, namespace, name, version, "lib.typ"))
    if readable(candidate) then
      return candidate
    end
  end

  return nil
end

local function resolve_import_path(bufnr, package, import_path)
  local from_root = resolve_with_root(package, import_path)
  if readable(from_root) then
    return from_root
  end

  if import_path:match("^@") then
    return resolve_typst_package(import_path)
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
