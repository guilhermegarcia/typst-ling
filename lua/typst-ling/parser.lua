local M = {}

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function strip_doc_prefix(line)
  return line:gsub("^%s*/// ?", "", 1)
end

local function first_sentence(lines)
  local saw_blank = false
  for _, raw in ipairs(lines) do
    local line = trim(raw)
    if line == "" then
      saw_blank = true
    elseif saw_blank or true then
      return line
    end
  end
  return nil
end

local function inline_code(line)
  return line:match("`([^`]+)`")
end

local function parse_example(lines)
  local in_examples = false
  local in_fence = false
  local fenced = {}

  for _, raw in ipairs(lines) do
    local line = raw
    local stripped = trim(line)

    if in_fence then
      if stripped:match("^```") then
        if #fenced > 0 then
          return table.concat(fenced, "\n")
        end
        in_fence = false
      else
        fenced[#fenced + 1] = line
      end
    elseif stripped:match("^Examples?:") then
      in_examples = true
      local code = inline_code(stripped)
      if code then
        return code
      end
    elseif in_examples and stripped:match("^```") then
      in_fence = true
    elseif in_examples and stripped:match("^%- ") then
      local code = inline_code(stripped)
      if code then
        return code
      end
    elseif in_examples and stripped ~= "" then
      local code = inline_code(stripped)
      if code then
        return code
      end
    end
  end

  return nil
end

function M.parse_lib(path)
  if not path or vim.fn.filereadable(path) == 0 then
    return {}
  end

  local lines = vim.fn.readfile(path)
  local docs = {}
  local block = {}

  for _, line in ipairs(lines) do
    if line:match("^%s*///") then
      block[#block + 1] = strip_doc_prefix(line)
    else
      local name = line:match("^#let%s+([%w%-]+)%s*=%s*[%w%-]+")
      if name and #block > 0 then
        docs[name] = {
          description = first_sentence(block),
          example = parse_example(block),
          file = path,
          search = "#let " .. name .. " = " .. name,
        }
      end
      block = {}
    end
  end

  return docs
end

return M
