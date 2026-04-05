local imports = require("typst-ling.imports")

local M = {}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "typst-ling" })
end

local function tokenize(input)
  local tokens = {}
  local buf = {}
  local brace_depth = 0

  local function flush()
    if #buf == 0 then
      return
    end
    local token = table.concat(buf):gsub("^%s+", ""):gsub("%s+$", "")
    if token ~= "" then
      tokens[#tokens + 1] = token
    end
    buf = {}
  end

  for ch in input:gmatch(".") do
    if ch == "{" then
      brace_depth = brace_depth + 1
      buf[#buf + 1] = ch
    elseif ch == "}" then
      brace_depth = math.max(brace_depth - 1, 0)
      buf[#buf + 1] = ch
    elseif brace_depth > 0 then
      buf[#buf + 1] = ch
    elseif ch == "[" or ch == "]" then
      flush()
      tokens[#tokens + 1] = ch
    elseif ch:match("%s") then
      flush()
    else
      buf[#buf + 1] = ch
    end
  end
  flush()

  return tokens
end

local function parse_node(tokens, pos)
  if tokens[pos] ~= "[" then
    error("expected '[' while parsing tree")
  end

  if tokens[pos + 1] == "]" then
    return { label = "", children = {} }, pos + 2
  end

  local label = tokens[pos + 1]
  if not label or label == "]" then
    error("missing node label")
  end

  local node = { label = label, children = {} }
  pos = pos + 2

  while pos <= #tokens and tokens[pos] ~= "]" do
    if tokens[pos] == "[" then
      local child
      child, pos = parse_node(tokens, pos)
      node.children[#node.children + 1] = child
    else
      node.children[#node.children + 1] = tokens[pos]
      pos = pos + 1
    end
  end

  if tokens[pos] ~= "]" then
    error("unbalanced tree brackets")
  end

  return node, pos + 1
end

local function format_node(node, level)
  local indent = string.rep("  ", level)
  if node.label == "" and #node.children == 0 then
    return indent .. "[]"
  end

  local only_words = true
  for _, child in ipairs(node.children) do
    if type(child) ~= "string" then
      only_words = false
      break
    end
  end

  if only_words then
    local pieces = { node.label }
    vim.list_extend(pieces, node.children)
    return indent .. "[" .. table.concat(pieces, " ") .. "]"
  end

  local lines = { indent .. "[" .. node.label }
  local words = {}

  local function flush_words()
    if #words == 0 then
      return
    end
    lines[#lines + 1] = string.rep("  ", level + 1) .. table.concat(words, " ")
    words = {}
  end

  for _, child in ipairs(node.children) do
    if type(child) == "string" then
      words[#words + 1] = child
    else
      flush_words()
      lines[#lines + 1] = format_node(child, level + 1)
    end
  end
  flush_words()
  lines[#lines + 1] = indent .. "]"

  return table.concat(lines, "\n")
end

function M.format_tree(input)
  local tokens = tokenize(input)
  if #tokens == 0 then
    error("empty tree input")
  end

  local node, next_pos = parse_node(tokens, 1)
  if next_pos <= #tokens then
    error("unexpected trailing tokens after tree")
  end

  return format_node(node, 0)
end

local function line_offsets(lines)
  local offsets = { 0 }
  local total = 0
  for idx, line in ipairs(lines) do
    total = total + #line + 1
    offsets[idx + 1] = total
  end
  return offsets
end

local function absolute_pos(offsets, row, col)
  return offsets[row] + col + 1
end

local function pos_from_absolute(offsets, abs)
  local row = 1
  for idx = 1, #offsets do
    if offsets[idx] >= abs then
      row = idx - 1
      break
    end
  end
  if row < 1 then
    row = #offsets - 1
  end
  local col = abs - offsets[row] - 1
  return row, col
end

local function scan_string_end(text, start_idx)
  local idx = start_idx + 1
  while idx <= #text do
    local ch = text:sub(idx, idx)
    if ch == "\\" then
      idx = idx + 2
    elseif ch == '"' then
      return idx
    else
      idx = idx + 1
    end
  end
  return nil
end

local function scan_call_end(text, open_idx)
  local depth = 1
  local idx = open_idx + 1
  while idx <= #text do
    local ch = text:sub(idx, idx)
    if ch == '"' then
      local string_end = scan_string_end(text, idx)
      if not string_end then
        return nil
      end
      idx = string_end + 1
    elseif ch == "(" then
      depth = depth + 1
      idx = idx + 1
    elseif ch == ")" then
      depth = depth - 1
      if depth == 0 then
        return idx
      end
      idx = idx + 1
    else
      idx = idx + 1
    end
  end
  return nil
end

local function first_tree_string(call_text)
  local input_start = call_text:find("input%s*:%s*\"")
  if input_start then
    local quote_idx = call_text:find('"', input_start, true)
    local quote_end = scan_string_end(call_text, quote_idx)
    if quote_end then
      return quote_idx, quote_end
    end
  end

  local idx = 1
  while idx <= #call_text do
    local ch = call_text:sub(idx, idx)
    if ch == '"' then
      local quote_end = scan_string_end(call_text, idx)
      if quote_end then
        return idx, quote_end
      end
      return nil
    end
    idx = idx + 1
  end
  return nil
end

local function current_tree_string_range(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local text = table.concat(lines, "\n")
  local offsets = line_offsets(lines)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_abs = absolute_pos(offsets, cursor[1], cursor[2])

  local best = nil
  local search_from = 1
  while true do
    local start_pos, end_pos = text:find("#tree%s*%(", search_from)
    if not start_pos then
      break
    end

    local open_idx = text:find("%(", start_pos)
    local close_idx = scan_call_end(text, open_idx)
    if close_idx and cursor_abs >= start_pos and cursor_abs <= close_idx + 1 then
      best = { start_pos = start_pos, open_idx = open_idx, close_idx = close_idx }
    end
    search_from = end_pos + 1
  end

  if not best then
    return nil
  end

  local call_text = text:sub(best.open_idx + 1, best.close_idx - 1)
  local quote_start, quote_end = first_tree_string(call_text)
  if not quote_start or not quote_end then
    return nil
  end

  local abs_start = best.open_idx + quote_start + 1
  local abs_end = best.open_idx + quote_end
  local start_row, start_col = pos_from_absolute(offsets, abs_start)
  local end_row, end_col = pos_from_absolute(offsets, abs_end)

  return {
    start_row = start_row - 1,
    start_col = start_col,
    end_row = end_row - 1,
    end_col = end_col,
    text = call_text:sub(quote_start + 1, quote_end - 1),
  }
end

function M.reindent_current()
  if not imports.in_typst_buffer(0) then
    notify("typst-ling only applies to Typst buffers.", vim.log.levels.WARN)
    return
  end

  if not imports.has(0, "synkit") then
    notify("synkit not imported in this buffer.", vim.log.levels.INFO)
    return
  end

  local range = current_tree_string_range(0)
  if not range then
    notify("No #tree() input found at the cursor.", vim.log.levels.INFO)
    return
  end

  local ok, formatted = pcall(M.format_tree, range.text)
  if not ok then
    notify(("Could not reindent tree: %s"):format(formatted), vim.log.levels.WARN)
    return
  end

  local replacement = vim.split(formatted, "\n", { plain = true })
  if #replacement > 1 then
    for idx = 2, #replacement do
      replacement[idx] = " " .. replacement[idx]
    end
  end
  vim.api.nvim_buf_set_text(0, range.start_row, range.start_col, range.end_row, range.end_col, replacement)
end

return M
