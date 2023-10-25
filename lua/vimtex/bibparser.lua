-- VimTeX - LaTeX plugin for Vim
--
-- Maintainer: Karl Yngve Lervåg
-- Email:      karl.yngve@gmail.com
--

---Parse input line as middle or tail part of an entry
---@param item table The current entry
---@param line string The new line to parse
---@return table item Current entry with updated body
local function parse_tail(item, line)
  item.level = item.level
    + line:gsub("[^{]", ""):len()
    - line:gsub("[^}]", ""):len()
  if item.level > 0 then
    item.body = item.body .. line
  else
    item.body = item.body .. vim.fn.matchstr(line, [[.*\ze}]])
    item.parsed = true
  end

  return item
end

---Parse the head part of an entry
---@param file string The path to the bibtex file-asd
---@param lnum integer The line number for the entry
---@param line string The line content of the entry
---@return table item Current entry with updated body
local function parse_head(file, lnum, line)
  local matches = vim.fn.matchlist(line, [[\v^\@(\w+)\s*\{\s*(.*)]])
  if #matches == 0 then
    return {}
  end

  local type = string.lower(matches[2])
  if type == "preamble" or type == "comment" then
    return {}
  end

  return parse_tail({
    level = 1,
    body = "",
    source_file = file,
    source_lnum = lnum,
    type = type,
  }, matches[3])
end

---Parse the value part of a bib entry tag until separating comma or end.
---The value is likely a quoted string and may possibly be a concatenation of
---strings. The value may also contain abbreviations defined by @string
---entries.
---@param body string
---@param head integer
---@param strings table<string, string>
---@param pre_value string
---@return string value The parsed value
---@return integer head New head position
local function get_tag_value_concat(body, head, strings, pre_value)
  local value = ""
  local new_head = head

  if body:sub(head + 1, head + 1) == "{" then
    local sum = 1
    local i = head + 1
    local n = #body

    while sum > 0 and i <= n do
      local char = body:sub(i + 1, i + 1)
      if char == "{" then
        sum = sum + 1
      elseif char == "}" then
        sum = sum - 1
      end

      i = i + 1
    end

    value = body:sub(head + 2, i - 1)
    new_head = vim.fn.matchend(body, [[^\s*]], i)
  elseif body:sub(head + 1, head + 1) == [["]] then
    local index = vim.fn.match(body, [[\\\@<!"]], head + 1)
    if index < 0 then
      return "bibparser.lua: get_tag_value_concat failed", -1
    end

    value = body:sub(head + 1 + 1, index - 1 + 1)
    new_head = vim.fn.matchend(body, [[^\s*]], index + 1)
  elseif vim.fn.match(body, [[^\w]], head) >= 0 then
    value = vim.fn.matchstr(body, [[^\w[0-9a-zA-Z_-]*]], head)
    new_head = vim.fn.matchend(body, [[^\s*]], head + vim.fn.strlen(value))
    value = vim.fn.get(strings, value, [[@(]] .. value .. [[)]])
  end

  if body:sub(new_head + 1, new_head + 1) == "#" then
    new_head = vim.fn.matchend(body, [[^\s*]], new_head + 1)
    return get_tag_value_concat(body, new_head, strings, pre_value .. value)
  end

  return pre_value .. value, vim.fn.matchend(body, [[^,\s*]], new_head)
end

---Parse the value part of a bib entry tag until separating comma or end.
---@param body string
---@param head integer
---@param strings table<string, string>
---@return string value The parsed value
---@return integer head New head position
local function get_tag_value(body, head, strings)
  -- First check if the value is simply a number
  if vim.regex([[\d]]):match_str(body:sub(head + 1, head + 1)) then
    local value = vim.fn.matchstr(body, [[^\d\+]], head)
    local new_head =
      vim.fn.matchend(body, [[^\s*,\s*]], head + vim.fn.len(value))
    return value, new_head
  end

  return get_tag_value_concat(body, head, strings, "")
end

---Parse tag from string (e.g. author, title, etc)
---@param body string Raw text in which to find tag
---@param head integer Where to start search for tag
---@return string tag_name The parsed tag
---@return integer head New head position
local function get_tag_name(body, head)
  local matches = vim.fn.matchlist(body, [[^\v([-_:0-9a-zA-Z]+)\s*\=\s*]], head)
  if #matches == 0 then
    return "", -1
  end

  return string.lower(matches[2]), head + vim.fn.strlen(matches[1])
end

---Parse an item
---@param item table
---@param strings table<string, string>
---@return nil
local function parse_item(item, strings)
  local parts = vim.fn.matchlist(item.body, [[\v^([^, ]*)\s*,\s*(.*)]])

  item.key = parts[2]
  if item.key == nil or item.key == "" then
    return nil
  end

  item.level = nil
  item.parsed = nil
  item.body = nil

  local body = parts[3]
  local tag = ""
  local value
  local head = 0
  while head >= 0 do
    if tag == "" then
      tag, head = get_tag_name(body, head)
    else
      value, head = get_tag_value(body, head, strings)
      item[tag] = value
      tag = ""
    end
  end

  return item
end

---Parse a string entry
---@param raw_string string
---@return string key
---@return string value
local function parse_string(raw_string)
  local matches =
    vim.fn.matchlist(raw_string, [[\v^\s*(\S+)\s*\=\s*"(.*)"\s*$]])
  if vim.fn.empty(matches[3]) == 0 then
    return matches[2], matches[3]
  end

  matches = vim.fn.matchlist(raw_string, [[\v^\s*(\S+)\s*\=\s*\{(.*)\}\s*$]])
  if vim.fn.empty(matches[3]) == 0 then
    return matches[2], matches[3]
  end

  return "", ""
end

local M = {}

---Parse the specified bibtex file
---The parser adheres to the format description found here:
---http://www.bibtex.org/Format/
---@param file string
---@return table[]
M.parse = function(file)
  if file == nil or not vim.fn.filereadable(file) then
    return {}
  end

  local items = {}
  local strings = {}

  local item = {}
  local key, value
  local lines = vim.fn.readfile(file)
  for lnum = 1, #lines do
    local line = lines[lnum]

    if vim.tbl_isempty(item) then
      item = parse_head(file, lnum, line)
    else
      item = parse_tail(item, line)
    end

    if item.parsed then
      if item.type == "string" then
        key, value = parse_string(item.body)
        if key ~= "" then
          strings[key] = value
        end
      else
        table.insert(items, item)
      end
      item = {}
    end
  end

  local result = {}
  for _, x in ipairs(items) do
    table.insert(result, parse_item(x, strings))
  end
  return result
end

return M
